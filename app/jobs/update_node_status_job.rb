class UpdateNodeStatusJob < ApplicationJob
  queue_as :default

  def perform(node:)
    containers = Docker::Container.all({all: true}, node.docker_connection)

    containers.each do |container|
      slot = node.slots.where(container_id: container.id).first
      if slot
        if container.info["State"] == "exited"
          ReleaseSlotJob.perform_later(slot: slot)
          node.update_usage
        else
          UpdateTaskStatusJob.perform_later(Task.find(slot.current_task.id))
        end
      else
        Rails.logger.info("Container #{container.id} not attached with any slot")
        RemoveContainerJob.perform_later(node: node, container_id: container.id)
      end
    end
  end
end
