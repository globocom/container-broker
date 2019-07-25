class UpdateAllNodesStatusJob
  include Sidekiq::Worker

  def perform
    Node.available.each do |node|
      LockManager.new(type: "update-node-status", id: node.id, expire: 1.minute, wait: false).lock do
        UpdateNodeStatusJob.perform_later(node: node)
      end
    end
  end
end
