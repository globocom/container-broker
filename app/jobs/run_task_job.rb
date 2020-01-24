# frozen_string_literal: true

class RunTaskJob < ApplicationJob
  queue_as :default

  def perform(task:, slot:)
    Rails.logger.debug("Performing RunTaskJob for #{task} #{slot}")

    container_name = task.name # TODO: MOdificar por task.generate_name

    container_id = Runners::ServicesFactory
                   .fabricate(runner: slot.node.runner, service: :run_task)
                   .perform(task: task, slot: slot, container_name: container_name)

    task.mark_as_started!(container_id: container_id, slot: slot)
    Rails.logger.debug("#{task} marked as started")

    slot.mark_as_running(current_task: task, container_id: container_id)
    Rails.logger.debug("#{slot} marked as running")

    add_metric(task)
    task
  rescue StandardError => e
    Rails.logger.debug("Error in RunTaskJob: #{e}")

    slot.node.register_error(e.message) if e.is_a?(Node::NodeConnectionError)

    slot.release
    Rails.logger.debug("#{slot} released")

    task.mark_as_retry(error: e.message)
    Rails.logger.debug("#{task} marked as retry")

    add_metric(task)

    Rails.logger.debug("Performed RunTaskJob for #{task} #{slot}")
  end

  def add_metric(task)
    Metrics.new("tasks").count(
      task_id: task.id,
      name: task&.name,
      type: task&.execution_type,
      slot: task&.slot&.name,
      node: task&.slot&.node&.name,
      started_at: task.started_at,
      duration: task.milliseconds_waiting,
      error: task.error,
      status: task.status
    )
  end
end
