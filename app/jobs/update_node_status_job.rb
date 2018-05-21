class UpdateNodeStatusJob < DockerConnectionJob
  queue_as :default

  def perform(node:)
    @node = node

    puts "sleeping 5 seconds"
    sleep 5
    puts "slept"

    containers = Docker::Container.all({all: true}, node.docker_connection)

    attached_slots = []

    containers.each do |container|
      slot = node.slots.where(container_id: container.id).first
      if slot
        attached_slots << slot
        if container.info["State"] == "exited"
          if slot.status == "running"
              # slot.reload
              # if slot.status == "running" # if slot status STILLS running after locking
                slot.releasing!
                ReleaseSlotJob.perform_later(slot: MongoidSerializableModel.new(slot))
              # end
            # end
          end
        else
          # UpdateTaskStatusJob.perform_later(Task.find(slot.current_task.id))
        end
      else
        # Here we remove lost containers, like those unknown to container-broker or by some cause
        # not linked here. But we need to take care to not remove those just created because
        # there is a sligthly time between their creation and its slot link that cannot be locked
        # so we remove only containers created at a minimum of 5 minutes
        if Time.parse(Docker.info(node.docker_connection)["SystemTime"]) - Time.at(container.info["Created"]) > 5.minutes
          puts "Container #{container.id} not attached with any slot"
          Rails.logger.info("Container #{container.id} not attached with any slot")
          # RemoveContainerJob.perform_later(node: node, container_id: container.id)
        end
      end
    end

    # zombie_slots = node.slots.where(status: "running") - attached_slots
    # zombie_slots.each do |slot|
    #   # ReleaseSlotJob.perform_later(slot: MongoidSerializableModel.new(slot))
    # end
  end
end
