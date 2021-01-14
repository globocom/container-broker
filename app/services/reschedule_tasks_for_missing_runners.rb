# frozen_string_literal: true

class RescheduleTasksForMissingRunners
  attr_reader :started_tasks, :runner_ids

  def initialize(runner_ids:, started_tasks:)
    @started_tasks = started_tasks
    @runner_ids = runner_ids
  end

  def perform
    tasks_without_runner.each do |runner_id|
      task = started_tasks_group_by_runner_id[runner_id]
      message = "Task retryied because runner #{runner_id} is missing (#{task} #{task&.slot})"
      Rails.logger.debug(message)

      report_event(message: message, task: task, runner_id: runner_id)

      slot = task.slot
      task.mark_as_retry(error: message)
      slot&.release
    end
  end

  private

  def report_event(message:, task:, runner_id:)
    return unless Settings.sentry.enabled

    slot = task&.slot
    node = slot&.node
    Raven.capture_exception(
      message,
      level: :info,
      extra: {
        runner: slot&.node&.runner_provider,
        runner_id: runner_id,
        slot: {
          uuid: slot&.uuid,
          name: slot&.name,
          status: slot&.status,
          runner_id: slot&.runner_id
        },
        node: {
          uuid: node&.uuid,
          name: node&.name,
          status: node&.status
        },
        task: {
          uuid: task.uuid,
          name: task.name,
          status: task.status
        }
      }
    )
  end

  def tasks_without_runner
    started_tasks_group_by_runner_id.keys - runner_ids
  end

  def started_tasks_group_by_runner_id
    @started_tasks_group_by_runner_id ||= started_tasks
                                          .map(&:reload)
                                          .select(&:started?)
                                          .select(&:runner_id)
                                          .group_by(&:runner_id)
                                          .transform_values(&:first)
  end
end
