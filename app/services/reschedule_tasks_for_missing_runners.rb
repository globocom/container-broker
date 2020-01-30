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
      Rails.logger.debug("Retry task #{task} because runner #{runner_id} does not exist")
      slot = task.slot
      task.mark_as_retry(error: "Task retryied because runner #{runner_id} is missing")
      slot&.release
    end
  end

  private

  def tasks_without_runner
    started_tasks_group_by_runner_id.keys.map(&:to_s) - runner_ids
  end

  def started_tasks_group_by_runner_id
    @started_tasks_group_by_runner_id ||= started_tasks
                                          .map(&:reload)
                                          .select(&:started?)
                                          .group_by(&:runner_id)
                                          .transform_values(&:first)
  end
end
