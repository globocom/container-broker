class MonitorUnresponsiveNodeJob < ApplicationJob
  queue_as :default

  def perform(node:)
    Docker.info(node.docker_connection)
    node.update(available: true, last_error: nil)
  rescue StandardError => e
    node.update(last_error: e.message)
    Rails.logger.info("Node #{node} still unresponsive")
  end
end
