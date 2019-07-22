class RunTasksJob < ApplicationJob
  def perform
    return unless Node.available.any?

    pending_tasks.each do |pending_task|
      slot = AllocateSlot.new(execution_type: pending_task.execution_type).call

      if slot
        RunTaskJob.perform_later(slot: slot, task: pending_task)
      elsif Slot.where(execution_type: pending_task.execution_type).none?
        pending_task.no_execution_type!
      end
    end
  end

  private

  def pending_tasks
    FetchTask.all_pending
  end
end
