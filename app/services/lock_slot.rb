# frozen_string_literal: true

class LockSlot
  attr_reader :execution_type, :node

  def initialize(execution_type:, node: nil)
    @execution_type = execution_type
    @node = node
  end

  def perform
    return unless first_available

    LockManager.new(type: self.class.to_s, id: "", expire: 10.seconds, wait: true).lock do
      first_available.tap do |slot|
        slot.attaching! if slot
      end
    end
  end

  def first_available
    FindAvailableSlot.new(execution_type: execution_type, node: node).call
  end
end
