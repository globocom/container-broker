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

    FriendlyNameSlots.new(node: node).perform
  end

  def increment?
    amount > count_by_execution_type
  end

  def decrement?
    amount < count_by_execution_type
  end

  private

  def count_by_execution_type
    node.slots.where(execution_type: execution_type).count
  end

  def amount
    node.slots_execution_types[execution_type].to_i
  end

  def increment_slots
    node.slots.create!(execution_type: execution_type) while increment?

    RunTasksJob.perform_later(execution_type: execution_type)
  end

  def decrement_slots
    while decrement?
      slot = LockSlot.new(execution_type: execution_type, node: node).perform
      break unless slot
      slot.destroy!
    end
  end
end
