class RunTasksJob < ApplicationJob
  def perform
    return unless executions_types_of_idle_slots.any?

    while pending_task = get_and_alocate_task
      slot = AllocateSlot.new(execution_type: pending_task.execution_type).call

      if slot
        RunTaskJob.perform_later(slot: slot, task: pending_task)
      else
        pending_task.waiting!
        break
      end
    end
  end

  private

  def get_and_alocate_task
    FetchTask.new(execution_types: executions_types_of_idle_slots).call
  end

  def executions_types_of_idle_slots
    Slot
      .where(node_id: { '$in': Node.available.pluck(:id) })
      .idle
      .pluck(:execution_type)
      .uniq
  end
end
