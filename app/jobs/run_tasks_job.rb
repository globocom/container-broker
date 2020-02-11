# frozen_string_literal: true

class RunTasksJob < ApplicationJob
  attr_reader :execution_type

  def perform(execution_type:)
    @execution_type = execution_type

    enqueue_tasks
  end

  private

  def enqueue_tasks
    while have_pending_tasks? && (slot = lock_slot)
      task = lock_task
      if task
        Rails.logger.debug "Perform_later RunTaskJob for #{slot} #{task}"
        RunTaskJob.perform_later(slot: slot, task: task)
      else
        slot.idle!
        break
      end
    end
  end

  def lock_slot
    LockSlot.new(execution_type: execution_type).perform
  end

  def lock_task
    lock_task_service.perform
  end

  def have_pending_tasks?
    lock_task_service.any_pending?
  end

  def lock_task_service
    @lock_task_service ||= LockTask.new(execution_type: execution_type)
  end
end
