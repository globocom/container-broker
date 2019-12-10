# frozen_string_literal: true

class TimeoutFailedTasksJob < ApplicationJob
  queue_as :default

  def perform(*_args)
    timeout_failed_tasks
  end

  def timeout_failed_tasks
    failed_tasks_to_timeout.map do |task|
      Rails.logger.debug("Marking task as error due to timeout: #{task.uuid}")

      task.error!

      persist_logs(task)
    end
  end

  def failed_tasks_to_timeout
    Task.failed.where(:finished_at.lt => Time.current - Settings.timeout_tasks_after_hours)
  end

  private

  def persist_logs(task)
    existent_logs = task.get_logs || ""

    task.set_logs(existent_logs + "\nThis task was automatically marked as error due to timeout.\n")

    task.save!
  end
end
