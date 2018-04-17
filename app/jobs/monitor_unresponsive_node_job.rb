class MonitorUnresponsiveNodeJob < ApplicationJob
  queue_as :default

  def perform(node:)
    Docker.info(node.docker_connection)
    node.update(available: true)
  rescue StandardError => e
    Rails.logger.info("Node #{node} still unresponsive")
  end
end
