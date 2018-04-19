class RunTasksJob < ApplicationJob

  def perform
    while FetchTask.first_pending && AllocateSlot.first_available do
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
