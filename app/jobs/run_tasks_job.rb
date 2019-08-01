class RunTasksJob < ApplicationJob
  def perform(execution_type:)
    while have_pending_tasks?(execution_type) && (slot = lock_slot(execution_type))
      task = lock_task(execution_type)
      if task
        RunTaskJob.perform_later(slot: slot, task: task)
      else
        slot.idle!
        break
      end
    end
  end

  private

  def lock_slot(execution_type)
    AllocateSlot.new(execution_type: execution_type).call
  end

  def lock_task(execution_type)
    fetch_task_service(execution_type).call
  end

  def have_pending_tasks?(execution_type)
    fetch_task_service(execution_type).first_pending
  end

  def fetch_task_service(execution_type)
    @fetch_task_service ||= FetchTask.new(execution_type: execution_type)
  end
end
