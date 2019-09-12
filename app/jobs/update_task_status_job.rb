# frozen_string_literal: true

class UpdateTaskStatusJob < ApplicationJob
  class InvalidContainerStatusError < StandardError; end

  queue_as :default

  def perform(task)
    Rails.logger.debug("Updating status for task #{task}")
    Rails.logger.debug("Task #{task} is running in slot #{task.slot}")

    container = FetchTaskContainer.new.call(task: task)

    container_state = container.info["State"]

    Rails.logger.debug("Got container #{container.id} with state #{container_state}")

    container_status = container_state["Status"]
    exit_code = container_state["ExitCode"]

    task.started_at = container_state["StartedAt"]

    if container_status == "exited"
      Rails.logger.debug("Container is in status #{container_status} and exit code #{exit_code}")

      task.exit_code = exit_code
      task.finished_at = container_state["FinishedAt"]

      if exit_code.zero?
        Rails.logger.debug("Marking task as completed and no errors")
        task.completed!
        task.error = nil
      else
        Rails.logger.debug("Marked task for retry and set error as #{container_state["Error"]}")
        task.error = container_state["Error"]
        task.retry
      end
    else
      raise InvalidContainerStatusError, "Container status should be exited (current status: #{container_status})"
    end

    add_metric(task)

    task.save!

    if task.persist_logs && container_status == "exited"
      Rails.logger.debug("Persisting logs for #{task}")
      # streaming_logs avoids some encoding issues and should be safe since container status = exited
      # (see https://github.com/swipely/docker-api/issues/290 for reference)
      container_logs = container.streaming_logs(stdout: true, stderr: true, tail: 100)

      task.set_logs(container_logs)
      task.save!
    end
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
      status: task.status,
      origin: "container-broker"
    )
  end
end
