# frozen_string_literal: true

class MonitorUnresponsiveNodeJob < ApplicationJob
  queue_as :default

  def perform(node:)
    Runners::ServicesFactory
      .fabricate(runner: node.runner, service: :node_availability)
      .perform(node: node)
    node.available!
    node.update!(last_error: nil)

    RunTasksForAllExecutionTypesJob.perform_later
  rescue StandardError => e
    node.register_error(e.message)
    Rails.logger.info("#{node} still unresponsive")
  end
end
