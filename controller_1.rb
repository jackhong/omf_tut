# Need omf_rc gem to be required
#
require 'omf_rc'

# By using default namespace OmfRc::ResourceProxy, the module defined could be loaded automatically.
#
module OmfRc::ResourceProxy::Garage
  # Include DSL module, which provides all DSL helper methods
  #
  include OmfRc::ResourceProxyDSL

  # DSL method register_proxy will register this module definition,
  # where :garage become the :type of the proxy.
  #
  register_proxy :garage
end

module OmfRc::ResourceProxy::Engine
  include OmfRc::ResourceProxyDSL

  # You can specify what kind of proxy can create it, this case, :garage
  #
  register_proxy :engine, :create_by => :garage

  # DSL method property will define proxy's internal properties,
  # and you can provide initial default value.
  #
  property :manufacturer, :default => "Cosworth"
  property :max_rpm, :default => 12500
  property :rpm, :default => 1000
end

# This init method will set up your run time environment,
# communication, eventloop, logging etc. We will explain that later.
#
OmfCommon.init(:development, communication: { url: 'xmpp://localhost' }) do
  OmfCommon.comm.on_connected do |comm|
    info "Garage controoler >> Connected to XMPP server"
    garage = OmfRc::ResourceFactory.create(:garage, uid: 'garage')
    comm.on_interrupted { garage.disconnect }
  end
end
