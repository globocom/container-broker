class MigrateTasksFromDeadNodeJob < ApplicationJob
  queue_as :default

  def perform(node:)
    node.slots.reject(&:idle?).each do |slot|
      task = slot.current_task
      task.retry if task.starting? || task.started? || task.running?

      slot.release
    end
  end
end
