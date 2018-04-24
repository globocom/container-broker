class MonitorUnresponsiveNodesJob
  include Sidekiq::Worker

  def perform
    Node.where(available: false).each do |node|
      MonitorUnresponsiveNodeJob.perform_later(node: node)
    end
  end
end
