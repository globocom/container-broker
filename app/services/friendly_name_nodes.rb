# frozen_string_literal: true

class FriendlyNameNodes
  def perform
    Node.order(runner_provider: :desc, hostname: :asc, id: :asc).each_with_index do |node, index|
      node.update(name: format("n%<sequence>03d%<provider>s", sequence: (index + 1), provider: node.runner_provider.first))
      FriendlyNameSlots.new(node: node).perform
    end
  end
end
