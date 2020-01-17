# frozen_string_literal: true

class MonitorUnresponsiveNodeJob < ApplicationJob
  queue_as :default

  def perform(node:)
    Runners::ServicesFactory
      .fabricate(runner: node.runner, service: :monitor_unresponsive_node)
      .perform(node: node)
  end
end
