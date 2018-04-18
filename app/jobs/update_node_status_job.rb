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
              slot.update(status: "releasing")
            end
            ReleaseSlotJob.perform_later(slot: MongoidSerializableModel.new(slot))
          end
        else
          # UpdateTaskStatusJob.perform_later(Task.find(slot.current_task.id))
        end
      else
        Rails.logger.info("Container #{container.id} not attached with any slot")
        RemoveContainerJob.perform_later(node: node, container_id: container.id)
      end
    end
  end
end
