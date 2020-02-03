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

    def remove_unknown_runner(node:, runner_id:)
      Rails.logger.debug("Slot not found for container #{runner_id}")

      if Settings.ignore_containers.none? { |ignored_name| runner_id.start_with?(ignored_name) }
        # It is needed to select the container using just any of its names
        RemoveRunnerJob.perform_later(node: node, runner_id: runner_id)
      else
        Rails.logger.debug("Container #{runner_id} is ignored for removal")
      end
    end

    def send_metrics(node:, execution_infos:)
      runners_count = execution_infos
                      .group_by(&:status)
                      .transform_keys { |k| "#{k}_runners".to_sym }
                      .transform_values(&:count)

      data = {
        hostname: node.hostname,
        runner_type: node.runner,
        capacity_reached: node.runner_capacity_reached,
        schedule_pending: execution_infos.count(&:schedule_pending?),
        total_runners: execution_infos.count
      }

      Metrics.new("runners").count(data.merge(runners_count))
    end
  end
end
