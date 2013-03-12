require 'rubygems'
require 'omf_common'

OmfCommon.init(:development, communication: { url: 'xmpp://localhost' }) do
  OmfCommon.comm.on_connected do |comm|
    info "Engine test script >> Connected to XMPP"

    comm.subscribe('garage') do |garage|
      unless garage.error?
        garage.request([:uid, :type]) do |reply_msg|
          reply_msg.each_property do |k, v|
            info "#{k} >> #{v}"
          end
        end
      else
        error garage.inspect
      end
    end

    OmfCommon.eventloop.after(5) { comm.disconnect }
    comm.on_interrupted { comm.disconnect }
  end
end
