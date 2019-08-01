class ReleaseSlotJob < ApplicationJob
  queue_as :default

  def perform(slot:)
    Rails.logger.debug("ReleaseSlotJob for #{slot}")
    UpdateTaskStatusJob.perform_now(slot.current_task)

    Rails.logger.debug("Enqueueing container removal")
    RemoveContainerJob.perform_later(node: MongoidSerializableModel.new(slot.node), container_id: slot.container_id) if Settings.delete_container_after_run

    check_for_slot_removal = CheckForSlotRemoval.new(slot: slot)
    check_for_slot_removal.perform
    if check_for_slot_removal.removed?
      Rails.logger.debug("Slot removed and will not be released")
    else
      slot.release
      Rails.logger.debug("Slot released (#{slot.status})")
    end
  end
end
