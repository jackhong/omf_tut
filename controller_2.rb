require 'omf_rc'

module OmfRc::ResourceProxy::Garage
  include OmfRc::ResourceProxyDSL

  register_proxy :garage
end

module OmfRc::ResourceProxy::Engine
  include OmfRc::ResourceProxyDSL

  register_proxy :engine, :create_by => :garage

  property :manufacturer, :default => "Cosworth"
  property :max_rpm, :default => 12500
  # Add additional property to store rpm and throttle
  #
  property :rpm, :default => 1000
  property :throttle, :default => 0

  hook :before_ready do |engine|
    # Constantly calculate RPM value, rules are:
    #
    # * Applying 100% throttle will increase RPM by 5000 per second
    # * Engine will reduce RPM by 500 per second when no throttle applied
    #
    OmfCommon.eventloop.every(2) do
      engine.property.rpm += (engine.property.throttle * 5000 - 500).to_i
      engine.property.rpm = 1000 if engine.property.rpm < 1000
    end
  end

  # Then we simply register a configure property handler for throttle,
  # We expect a percentage value received and convert into decimal value
  #
  configure :throttle do |engine, value|
    engine.property.throttle = value.to_f / 100.0
  end
end

OmfCommon.init(:development, communication: { url: 'xmpp://localhost' }) do
  OmfCommon.comm.on_connected do |comm|
    info "Garage controoler >> Connected to XMPP server"
    garage = OmfRc::ResourceFactory.create(:garage, uid: 'garage')
    comm.on_interrupted { garage.disconnect }
  end
end
