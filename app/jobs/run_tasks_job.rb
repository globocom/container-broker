# frozen_string_literal: true

class RunTasksJob < ApplicationJob
  def perform(execution_type:)
    while have_pending_tasks?(execution_type) && (slot = lock_slot(execution_type))
      task = lock_task(execution_type)
      if task
        Rails.logger.debug "Perform_later RunTaskJob for #{slot} #{task}"
        RunTaskJob.perform_later(slot: slot, task: task)
      else
        slot.idle!
        break
      end
    end
  end

  private

  def lock_slot(execution_type)
    LockSlot.new(execution_type: execution_type).perform
  end

  def lock_task(execution_type)
    lock_task_service(execution_type).call
  end

  def have_pending_tasks?(execution_type)
    lock_task_service(execution_type).first_pending
  end

  def lock_task_service(execution_type)
    @lock_task_service ||= LockTask.new(execution_type: execution_type)
  end
end
