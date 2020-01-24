# frozen_string_literal: true

class ReleaseSlotJob < ApplicationJob
  class InvalidSlotContainerId < StandardError; end
  queue_as :default

  def perform(slot:, container_id: nil)
    Rails.logger.debug("ReleaseSlotJob for #{slot} and container #{container_id}")

    check_same_container_id(slot: slot, container_id: container_id)

    UpdateTaskStatusJob.perform_now(slot.current_task.reload)

    Rails.logger.debug("Enqueueing container removal")
    RemoveContainerJob.perform_later(node: MongoidSerializableModel.new(slot.node), container_id: slot.container_id) if Settings.delete_container_after_run

    check_for_slot_removal = CheckForSlotRemoval.new(slot: slot)
    check_for_slot_removal.perform
    if check_for_slot_removal.removed?
      Rails.logger.debug("Slot removed and wont be released")
    else
      slot.release
      Rails.logger.debug("Slot released (#{slot.status})")
    end
  rescue StandardError => e
    Rails.logger.debug("Error in ReleaseSlotJob for #{slot}: #{e}")
    slot.node.register_error(e.message)
    raise
  end

  def check_same_container_id(slot:, container_id:)
    return if container_id == slot.container_id

    error_message = "Current container id (#{slot.container_id}) in #{slot} is different than the provided (#{container_id})"

    Rails.logger.error(error_message)

    raise InvalidSlotContainerId, error_message
  end
end
