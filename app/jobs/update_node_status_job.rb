class UpdateNodeStatusJob < DockerConnectionJob
  queue_as :default

  def perform(node:)
    @node = node

    containers = Docker::Container.all({all: true}, node.docker_connection)

    containers.each do |container|
      slot = node.slots.where(container_id: container.id).first
      if slot
        if container.info["State"] == "exited"
          if slot.status == "running"
            LockManager.lock("release_slot_#{slot.id}", 2000) do
              if slot.status == "running" # if slot status STILLS running after locking
                slot.update(status: "releasing")
                ReleaseSlotJob.perform_later(slot: MongoidSerializableModel.new(slot))
              end
            end
          end
        else
          # UpdateTaskStatusJob.perform_later(Task.find(slot.current_task.id))
        end
      else
        puts "Container #{container.id} not attached with any slot"
        Rails.logger.info("Container #{container.id} not attached with any slot")
        RemoveContainerJob.perform_later(node: node, container_id: container.id)
      end
    end
  end
end
