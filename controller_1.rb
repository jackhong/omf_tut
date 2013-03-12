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
end

OmfCommon.init(:development, communication: { url: 'xmpp://localhost' }) do
  OmfCommon.comm.on_connected do |comm|
    info "Garage controoler >> Connected to XMPP server"
    garage = OmfRc::ResourceFactory.new(:garage, uid: 'garage')
    comm.on_interrupted { garage.disconnect }
  end
end
