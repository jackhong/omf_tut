require 'omf_common'

def create_engine(garage)
  garage.create(:engine, hrn: 'my_engine') do |reply_msg|
    if reply_msg.success?
      engine = reply_msg.resource

      engine.on_subscribed do
        info ">>> Connected to newly created engine #{reply_msg[:hrn]}(id: #{reply_msg[:res_id]})"
        on_engine_created(engine)
      end

      OmfCommon.eventloop.after(10) do
        release_engine(garage, engine)
      end
    else
      error ">>> Resource creation failed - #{reply_msg[:reason]}"
    end
  end
end

def on_engine_created(engine)
  info "> Now we will apply 50% throttle to the engine"
  engine.configure(throttle: 50)

  # Every 2 seconds, we send a request to engine, request its RPM value
  #
  OmfCommon.eventloop.every(2) do
    engine.request([:rpm]) do |reply_msg|
      info "RPM >> #{reply_msg[:rpm]}"
    end
  end

  # Some time later, we configure the throttle back to 0
  #
  OmfCommon.eventloop.after(5) do
    info "> We want to reduce the throttle to 0"
    engine.configure(throttle: 0)
  end
end

def release_engine(garage, engine)
  info ">>> Release engine"
  garage.release(engine) do |reply_msg|
    info "Engine #{reply_msg[:res_id]} released"
    OmfCommon.comm.disconnect
  end
end

OmfCommon.init(:development, communication: { url: 'xmpp://localhost' }) do
  OmfCommon.comm.on_connected do |comm|
    info "Engine test script >> Connected to XMPP"

    comm.subscribe('garage') do |garage|
      unless garage.error?
        create_engine(garage)
      else
        error garage.inspect
      end
    end

    OmfCommon.eventloop.after(20) { comm.disconnect }
    comm.on_interrupted { comm.disconnect }
  end
end
