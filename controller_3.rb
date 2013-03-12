require 'rubygems'
require 'omf_rc'
require 'omf_rc/resource_factory'

module OmfRc::ResourceProxy::Garage
  include OmfRc::ResourceProxyDSL

  register_proxy :garage

  hook :before_create do |garage, new_resource_type, new_resource_opts|
    raise 'Fuck off'
    info "Garage has #{garage.children.size} engine(s)"
    info "You asked me to create a new #{new_resource_type} with options: #{new_resource_opts}"
  end

  hook :after_create do |garage, engine|
    info "Engine #{engine.uid} created"
  end
end

module OmfRc::ResourceProxy::Engine
  include OmfRc::ResourceProxyDSL

  register_proxy :engine, :create_by => :garage

  property :serial_number, :default => "0000"
  property :rpm, :default => 0

  hook :before_ready do |engine|
    engine.property.rpm = 1000
    info "Engine serial number is #{engine.property.serial_number}"
  end

  hook :after_initial_configured do |engine|
    info "Engine serial number is #{engine.property.serial_number}"
  end

  # before_release hook will be called before the resource is fully released, shut down the engine in this case.
  #
  hook :before_release do |engine|
    engine.property.rpm = 0
  end
end

OmfCommon.init(:development, communication: { url: 'xmpp://delta:pw@localhost' }) do
  OmfCommon.comm.on_connected do |comm|
    info "Garage controoler >> Connected to XMPP server"
    garage = OmfRc::ResourceFactory.new(:garage, uid: 'garage', hrn: 'my_garage')
    comm.on_interrupted { garage.disconnect }
  end
end
