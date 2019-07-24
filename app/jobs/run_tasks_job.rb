class RunTasksJob < ApplicationJob
  def perform
    return unless Node.available.any?

    pending_tasks.each do |pending_task|
      slot = AllocateSlot.new(execution_type: pending_task.execution_type).call

      if slot
        RunTaskJob.perform_later(slot: slot, task: pending_task)
      elsif Slot.where(execution_type: pending_task.execution_type).none?
        pending_task.no_execution_type!
      else
        pending_task.waiting!
      end
    end
  end

  private

  def pending_tasks
    pending_tasks = []

    while pending_task = FetchTask.new.call do
      pending_tasks << pending_task
    end

    pending_tasks
  end
end
