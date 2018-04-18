class ReleaseSlotJob < ApplicationJob
  queue_as :default

  def perform(slot:)
    UpdateTaskStatusJob.perform_now(slot.current_task)
    RemoveContainerJob.perform_later(node: MongoidSerializableModel.new(slot.node), container_id: slot.container_id)
    slot.release
  end
end
