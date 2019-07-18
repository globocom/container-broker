class RunTasksJob < ApplicationJob
  def perform
    return unless Node.available.any?

    pending_tasks.each do |pending_task|
      allocate_slot_service = AllocateSlot.new(tag: pending_task.tag)

      slot = allocate_slot_service.call

      if slot
        RunTaskJob.perform_later(slot: slot, task: pending_task)
      elsif Slot.where(tag: pending_task.tag).none?
        pending_task.no_tag_available!
      end
    end
  end

  private

  def pending_tasks
    FetchTask.all_pending
  end
end
