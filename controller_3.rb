require 'omf_rc'

module OmfRc::ResourceProxy::Garage
  include OmfRc::ResourceProxyDSL

  register_proxy :garage

  # before_create allows you access the current garage instance, the type of new resource it is going to create,
  # and initial options passed to be used for new resource
  #
  hook :before_create do |garage, new_resource_type, new_resource_opts|
    # Can check existing engines already created
    #
    info "Garage has #{garage.children.size} engine(s)"

    # Can verify new resource's options
    #
    info "You asked me to create a new #{new_resource_type} with options: #{new_resource_opts}"
  end

  # after_create hook has access to the current garage instance and newly created engine instance
  #
  hook :after_create do |garage, engine|
    # Can inspect or update newly created resource
    #
    info "Engine #{engine.uid} created"
  end
end

module OmfRc::ResourceProxy::Engine
  include OmfRc::ResourceProxyDSL

  register_proxy :engine, :create_by => :garage

  property :serial_number, :default => "0000"
  property :rpm, :default => 0

  # Use this to do initialisation/bootstrap
  #
  hook :before_ready do |engine|
    engine.property.rpm = 1000
    # Notice that now serial number hasn't been configured yet.
    #
    info "Engine serial number is #{engine.property.serial_number}"
  end

  # Since now new resource has been created and configured properly,
  # additional logic can be applied based on configured properties' state.
  #
  hook :after_initial_configured do |engine|
    # Notice now serial number is configured.
    #
    info "Engine serial number is #{engine.property.serial_number}"
  end

  # before_release hook will be called before the resource is fully released, shut down the engine in this case.
  #
  hook :before_release do |engine|
    engine.property.rpm = 0
  end
end

OmfCommon.init(:development, communication: { url: 'xmpp://localhost' }) do
  OmfCommon.comm.on_connected do |comm|
    info "Garage controoler >> Connected to XMPP server"
    garage = OmfRc::ResourceFactory.create(:garage, uid: 'garage', hrn: 'my_garage')
    comm.on_interrupted { garage.disconnect }
  end
end
