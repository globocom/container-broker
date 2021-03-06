# frozen_string_literal: true

class ReleaseSlotJob < ContainerBrokerBaseJob
  class InvalidSlotContainerId < StandardError; end
  queue_as :default

  def perform(slot:, runner_id:)
    Rails.logger.debug("ReleaseSlotJob for #{slot} and container #{runner_id}")

    if MigrateRunner.new(runner_id: runner_id).migrated?
      Rails.logger.debug("Ignores release slot for #{slot} because it's migrated")
      return
    end

    check_same_runner_id(slot: slot, runner_id: runner_id)

    UpdateTaskStatusJob.perform_now(slot.current_task.reload)

    Rails.logger.debug("Enqueueing container removal")
    RemoveRunnerJob.perform_later(node: MongoidSerializableModel.new(slot.node), runner_id: slot.runner_id) if Settings.delete_container_after_run

    check_for_slot_removal = CheckForSlotRemoval.new(slot: slot)
    check_for_slot_removal.perform
    if check_for_slot_removal.removed?
      Rails.logger.debug("Slot removed and wont be released")
    else
      slot.release
      Rails.logger.debug("Slot released (#{slot.status})")
    end
  rescue Runners::RunnerIdNotFoundError => e
    Rails.logger.debug("Runner #{runner_id} not found (#{e.message}). Task will be rescheduled in UpdateNodeStatus.")
  rescue StandardError => e
    Rails.logger.debug("Error in ReleaseSlotJob for #{slot}: #{e}")
    slot.node.register_error(e.message)
    raise
  end

  def check_same_runner_id(slot:, runner_id:)
    return if runner_id == slot.runner_id

    error_message = "Current container id (#{slot.runner_id}) in #{slot} is different than the provided (#{runner_id})"

    Rails.logger.error(error_message)

    raise InvalidSlotContainerId, error_message
  end
end
