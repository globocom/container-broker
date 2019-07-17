class RunTasksJob < ApplicationJob
  def perform
    while FetchTask.have_tasks? do
      first_pending = FetchTask.first_pending
      allocate_task_service = AllocateSlot.new(tag: first_pending.tag)

      if allocate_task_service.slots_available?
        task = FetchTask.new.call
        return if !task

        allocate_task_service = AllocateSlot.new(tag: task.tag)

        if task
          slot = allocate_task_service.call
          if slot
            RunTaskJob.perform_later(slot: slot, task: task)
          else
            task.waiting!
          end
        end
      end
    end
  end
end
