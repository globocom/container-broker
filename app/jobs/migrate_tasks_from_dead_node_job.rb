# frozen_string_literal: true

class MigrateTasksFromDeadNodeJob < ApplicationJob
  queue_as :default

  def perform(node:)
    LockManager.new(type: self.class.to_s, id: node.id, wait: false, expire: 1.minute).lock do
      Rails.logger.debug("Migrating tasks from #{node}")
      node.slots.reject(&:idle?).each do |slot|
        Rails.logger.debug("Migrating task for #{slot}")
        current_task = slot.current_task
        if current_task
          Rails.logger.debug("Retrying slot current task #{current_task}")
          current_task.retry if current_task.starting? || current_task.started? || current_task.running?
        else
          Rails.logger.debug("Slot does not have current task")
        end

        Rails.logger.debug("Releasing #{slot}")
        slot.release
        Rails.logger.debug("#{slot} released")
      end
    end
  end
end
