require 'rubygems'
require 'omf_rc'
require 'omf_rc/resource_factory'

module OmfRc::ResourceProxy::Garage
  include OmfRc::ResourceProxyDSL

  register_proxy :garage
end

module OmfRc::ResourceProxy::Engine
  include OmfRc::ResourceProxyDSL

  register_proxy :engine, :create_by => :garage

  property :manufacturer, :default => "Cosworth"
  property :max_rpm, :default => 12500
  property :rpm, :default => 1000
  property :throttle, :default => 0

  hook :before_ready do |engine|
    OmfCommon.eventloop.every(2) do
      engine.property.rpm += (engine.property.throttle * 5000 - 500).to_i
      engine.property.rpm = 1000 if engine.property.rpm < 1000
    end
  end

  configure :throttle do |engine, value|
    engine.property.throttle = value.to_f / 100.0
  end
end

OmfCommon.init(:development, communication: { url: 'xmpp://localhost' }) do
  OmfCommon.comm.on_connected do |comm|
    info "Garage controoler >> Connected to XMPP server"
    garage = OmfRc::ResourceFactory.new(:garage, uid: 'garage')
    comm.on_interrupted { garage.disconnect }
  end
end
