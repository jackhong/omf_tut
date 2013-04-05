require 'omf_common'

# We define a create_engine method here to contain all the logic around engine creation
#
def create_engine(garage)
  # We create an engine instance with a human readable name 'my_engine'
  #
  garage.create(:engine, hrn: 'my_engine') do |reply_msg|
    # This reply_msg will be the inform message issued by garage controller
    #
    if reply_msg.success?
      # Since we need to interact with engine's PubSub topic,
      # we call #resource method to construct a topic from the FRCP message content.
      #
      engine = reply_msg.resource

      # Because of the asynchronous nature, we need to use this on_subscribed callback
      # to make sure the operation in the block executed only when subscribed to the newly created engine's topic
      engine.on_subscribed do
        info ">>> Connected to newly created engine #{reply_msg[:hrn]}(id: #{reply_msg[:res_id]})"
      end

      # Then later on, we will ask garage again to release this engine.
      #
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
  # Only parent (garage) can release its child (engine)
  #
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
        # Now calling create_engine method we defined, with newly created garage topic object
        #
        create_engine(garage)
      else
        error garage.inspect
      end
    end

    OmfCommon.eventloop.after(10) { comm.disconnect }
    comm.on_interrupted { comm.disconnect }
  end
end
