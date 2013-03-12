require 'rubygems'
require 'omf_common'

def create_engine(garage)
  garage.create(:engine, hrn: 'my_engine') do |reply_msg|
    if reply_msg.success?
      engine = reply_msg.resource

      engine.on_subscribed do
        info ">>> Connected to newly created engine #{reply_msg[:hrn]}(id: #{reply_msg[:res_id]})"
      end

      OmfCommon.eventloop.after(3) do
        release_engine(garage, engine)
      end
    else
      error ">>> Resource creation failed - #{reply_msg[:reason]}"
    end
  end
end

def release_engine(garage, engine)
  info ">>> Release engine"
  garage.release(engine) do |reply_msg|
    info "Engine #{reply_msg[:res_id]} released"
    OmfCommon.comm.disconnect
  end
end

OmfCommon.init(:development, communication: { url: 'xmpp://lima:pw@localhost' }) do
  OmfCommon.comm.on_connected do |comm|
    info "Engine test script >> Connected to XMPP"

    comm.subscribe('garage') do |garage|
      unless garage.error?
        create_engine(garage)
      else
        error garage.inspect
      end
    end

    OmfCommon.eventloop.after(10) { comm.disconnect }
    comm.on_interrupted { comm.disconnect }
  end
end
