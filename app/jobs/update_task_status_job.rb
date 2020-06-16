# frozen_string_literal: true

class UpdateTaskStatusJob < ApplicationJob
  extend RequestIdFromTask

  class InvalidContainerStatusError < StandardError; end

  queue_as :default

  def perform(task)
    Rails.logger.debug("Updating status for task #{task}")
    Rails.logger.debug("Task #{task} is running in slot #{task.slot}")

    execution_info = task.slot.node.runner_service(:fetch_execution_info).perform(task: task)

    Rails.logger.debug("Got runner #{execution_info.id} with state #{execution_info.status}")

    unless execution_info.terminated?
      Rails.logger.debug("Runner should be terminated but it is #{execution_info.status}. Execution info is #{execution_info.to_h}")
      raise InvalidContainerStatusError,
            "Runner should be terminated (current status: #{execution_info.status})"
    end

    Rails.logger.debug("Container is in status #{execution_info.status} and exit code #{execution_info.exit_code}")

    task.exit_code = execution_info.exit_code
    task.started_at = execution_info.started_at
    task.finished_at = execution_info.finished_at

    persist_logs(task)

    if execution_info.success?
      Rails.logger.debug("Marking task as completed and no errors")
      task.error = nil
      task.completed!
    else
      Rails.logger.debug("Marked task for retry and set error as #{execution_info.error}")
      task.mark_as_retry(error: execution_info.error)
    end

    task.save!

    add_metric(task)
  end

  def persist_logs(task)
    return unless task.persist_logs

    Rails.logger.debug("Persisting logs for #{task}")
    container_logs = task.slot.node.runner_service(:fetch_logs).perform(task: task)
    task.set_logs(container_logs)
  end

  def add_metric(task)
    Metrics.new("tasks").count(
      task_id: task.id,
      event_id: task&.tags&.dig("event_id"),
      api_id: task&.tags&.dig("api_id").to_i,
      name: task&.name,
      type: task&.execution_type,
      slot: task&.slot&.name,
      node: task&.slot&.node&.name,
      started_at: task.started_at,
      finished_at: task.finished_at,
      duration: task.milliseconds_running,
      processing_time: task.seconds_running.to_i,
      error: task.error,
      status: task.status
    )
  end
end
