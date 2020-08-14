# frozen_string_literal: true

class UpdateAllNodesStatusJob < ContainerBrokerBaseJob
  def perform
    Node.available.each do |node|
      UpdateNodeStatusJob.perform_later(node: node)
    end
  end
end
