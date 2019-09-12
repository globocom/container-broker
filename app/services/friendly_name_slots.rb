# frozen_string_literal: true

class FriendlyNameSlots
  attr_reader :node

  def initialize(node:)
    @node = node
  end

  def perform
    node.slots.each_with_index do |slot, index|
      slot.update(name: "#{node.name}-s#{format("%02d", (index + 1))}-#{slot.execution_type}")
    end
  end
end
