class MonitorUnresponsiveNodesJob
  include Sidekiq::Worker

  def perform
    (Node.unstable + Node.unavailable).each do |node|
      MonitorUnresponsiveNodeJob.perform_later(node: node)
    end
  end
end
