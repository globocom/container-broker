class FriendlyNameNodes
  def call
    Node.all.to_a.each_with_index do |node, index|
      node.update(name: "n#{index + 1}")
      node.slots.each_with_index do |slot, index|
        slot.update(name: "#{node.name}-s#{index + 1}")
      end
    end
  end
end
