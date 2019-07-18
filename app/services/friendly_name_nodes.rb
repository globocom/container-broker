class FriendlyNameNodes
  def call
    Node.all.to_a.each_with_index do |node, index|
      node.update(name: "n#{"%02d" % (index + 1)}")
      node.slots.each_with_index do |slot, index|
        slot.update(name: "#{node.name}-s#{"%02d" % (index + 1)}-#{slot.execution_type}")
      end
    end
  end
end
