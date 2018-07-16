class MonitorUnresponsiveNodesJob
  include Sidekiq::Worker

  def perform
    Node.where(:status.in => ["unstable", "unavailable"]).each do |node|
      MonitorUnresponsiveNodeJob.perform_later(node: node)
    end
  end
end
