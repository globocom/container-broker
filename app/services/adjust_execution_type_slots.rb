# frozen_string_literal: true

class AdjustExecutionTypeSlots
  attr_reader :node, :execution_type

  def initialize(node:, execution_type:)
    @node = node
    @execution_type = execution_type
  end

  def perform
    increment_slots

    decrement_slots
  end

  def self.decrement_slot_if_needed(slot:)
    slot.destroy! if new(node: slot.node, execution_type: slot.execution_type).decrement_slots?
  end

  def increment?
    amount > count_by_execution_type
  end

  def decrement?
    amount < count_by_execution_type
  end

  private

  def count_by_execution_type
    node.slots.where(execution_type: execution_type).size
  end

  def amount
    node.slots_execution_types[execution_type].to_i
  end

  def increment_slots
    node.slots.create!(execution_type: execution_type) while increment?
  end

  def decrement_slots
    while decrement?
      slot = AllocateSlot.new(execution_type: execution_type, node: node).call
      break unless slot

      slot.destroy!
    end
  end
end
