class UpdateAllNodesStatusJob
  include Sidekiq::Worker

  def perform
    Node.available.each do |node|
      UpdateNodeStatusJob.perform_later(node: node)
    end
  end
end