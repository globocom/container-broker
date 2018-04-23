class RunTasksJob < ApplicationJob

  def perform
    while FetchTask.have_tasks? && AllocateSlot.slots_available? do
      task = FetchTask.new.call
      if task
        slot = AllocateSlot.new.call
        if slot
          RunTaskJob.perform_later(slot: slot, task: task)
        else
          task.update(status: "waiting")
        end
      end
    end
  end
end
