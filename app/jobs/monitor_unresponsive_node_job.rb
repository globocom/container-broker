# frozen_string_literal: true

class MonitorUnresponsiveNodeJob < ApplicationJob
  queue_as :default

  def perform(node:)
    node.run_with_lock_no_wait do
      node.runner_service(:node_availability).perform(node: node)
      node.available!
      node.update!(last_error: nil)
      RunTasksForAllExecutionTypesJob.perform_later
    end
  rescue StandardError => e
    node.register_error("#{e.class}: #{e.message}")

    Rails.logger.info("#{node} still unresponsive")
  end
end
