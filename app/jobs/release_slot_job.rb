class ReleaseSlotJob < DockerConnectionJob
  queue_as :default

  def perform(slot:)
    @node = slot.node

    UpdateTaskStatusJob.perform_now(slot.current_task)
    RemoveContainerJob.perform_now(node: slot.node, container_id: slot.container_id)
    slot.release
    slot.node.update_usage
  end
end
