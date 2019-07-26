class ReleaseSlotJob < ApplicationJob
  queue_as :default

  def perform(slot:)
    UpdateTaskStatusJob.perform_now(slot.current_task)
    RemoveContainerJob.perform_later(node: MongoidSerializableModel.new(slot.node), container_id: slot.container_id) if Settings.delete_container_after_run

    check_for_slot_removal = CheckForSlotRemoval.new(slot: slot)
    check_for_slot_removal.perform
    return if check_for_slot_removal.removed?

    slot.release
    RunTasksJob.perform_later
  end
end
