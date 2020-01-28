# frozen_string_literal: true

module Runners
  module UpdateNodeStatusHelper
    def check_slot_release(slot:, runner_id:)
      if slot.running?
        slot.releasing!
        Rails.logger.debug("Slot was running. Marked as releasing. Slot: #{slot}. Current task: #{slot.current_task}")
        ReleaseSlotJob.perform_later(slot: MongoidSerializableModel.new(slot), runner_id: runner_id)
      else
        Rails.logger.debug("Slot was not running (it was #{slot.status}). Ignoring.")
      end
    end

    def remove_unknown_runners(node:, runner_ids:)
      Rails.logger.debug("Slot not found for container #{runner_ids}")

      if Settings.ignore_containers.none? { |ignored_name| runner_ids.any? { |runner_id| runner_id.include?(ignored_name) } }
        # It is needed to select the container using just any of its names
        RemoveContainerJob.perform_later(node: node, runner_id: runner_ids.first)
      else
        Rails.logger.debug("Container #{runner_ids.join(",")} is ignored for removal")
      end
    end
  end
end
