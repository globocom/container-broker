# frozen_string_literal: true

class MigrateTasksFromDeadNodeJob < ApplicationJob
  queue_as :default

  def perform(node:)
    if node.available?
      Rails.logger.debug("Not migrating tasks because #{node} returned to available status")
      return
    end

    node.run_with_lock_no_wait do
      Rails.logger.debug("Migrating tasks from #{node}")
      node.slots.reject(&:available?).each do |slot|
        Rails.logger.debug("Migrating task for #{slot}")
        current_task = slot.current_task
        if current_task
          Rails.logger.debug("Retrying slot current task #{current_task}")
          current_task.mark_as_retry if current_task.starting? || current_task.started?
        else
          Rails.logger.debug("Slot does not have current task")
        end

        MigrateRunner.new(runner_id: slot.runner_id).migrate

        Rails.logger.debug("Releasing #{slot}")
        slot.release
        Rails.logger.debug("#{slot} released")
      end
    end
  end
end
