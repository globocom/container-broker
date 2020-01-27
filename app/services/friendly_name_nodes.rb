# frozen_string_literal: true

class FriendlyNameNodes
  def perform
    Node.order(id: :asc).each_with_index do |node, index|
      node.update(name: "n#{format("%02d%s", (index + 1), node.runner.first)}")
      FriendlyNameSlots.new(node: node).perform
    end
  end
end
