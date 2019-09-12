# frozen_string_literal: true

class MonitorUnresponsiveNodesJob
  include Sidekiq::Worker

  def perform
    Node.where(:status.in => %w[unstable unavailable]).each do |node|
      MonitorUnresponsiveNodeJob.perform_later(node: node)
    end
  end
end
