# frozen_string_literal: true

class CheckForSlotRemoval
  attr_reader :slot

  def initialize(slot:)
    @slot = slot
  end

  def perform
    return unless adjust_execution_type_slots_instance.decrement?

    slot.destroy!
    FriendlyNameSlots.new(node: slot.node.reload).perform

    @removed = true
  end

  def removed?
    @removed
  end

  private

  def adjust_execution_type_slots_instance
    AdjustExecutionTypeSlots.new(node: slot.node, execution_type: slot.execution_type)
  end
end
