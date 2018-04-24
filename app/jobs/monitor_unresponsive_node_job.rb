class MonitorUnresponsiveNodeJob < ApplicationJob
  queue_as :default

  def perform(node:)
    Docker.info(node.docker_connection)
    node.available!
  rescue StandardError => e
    node.update(last_error: e.message)
    Rails.logger.info("Node #{node} still unresponsive")
  end
end
