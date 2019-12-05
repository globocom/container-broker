# frozen_string_literal: true

class TimeoutFailedTasksJob < ApplicationJob
  queue_as :default

  def perform(*_args)
    timeout_failed_tasks
  end

  def timeout_failed_tasks
    tasks = failed_tasks

    tasks.map do |task|
      next unless task_live_time(task.finished_at) >= Settings.timeout_tasks_after_hours

      Rails.logger.debug("Marking task as error due to timeout: #{task.uuid}")

      task.error!
    end
  end

  def failed_tasks
    Task.where(status: "failed").to_a
  end

  def task_live_time(finished_at)
    (Time.parse(Time.zone.now.to_datetime.to_s) - Time.parse(finished_at.to_s)) / 3_600
  end
end
