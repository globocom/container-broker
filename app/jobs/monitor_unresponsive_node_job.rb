# frozen_string_literal: true

class MonitorUnresponsiveNodeJob < ApplicationJob
  queue_as :default

  def perform(node:)
    Runners::Fabricate.monitor_unresponsive_node(node: node).perform
  end
end
