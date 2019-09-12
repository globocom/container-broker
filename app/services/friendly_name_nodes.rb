# frozen_string_literal: true

class FriendlyNameNodes
  def perform
    Node.all.to_a.each_with_index do |node, index|
      node.update(name: "n#{format("%02d", (index + 1))}")
      FriendlyNameSlots.new(node: node).perform
    end
  end
end
