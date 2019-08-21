# frozen_string_literal: true

class AdjustNodeSlotsJob < ApplicationJob
  queue_as :default

  def perform(node:)
    lock_manager_instance(node).lock do
      node.reload
      all_execution_types(node).each do |execution_type|
        AdjustExecutionTypeSlots.new(
          node: node,
          execution_type: execution_type
          ).perform
      end
    end
  end

  private

  def all_execution_types(node)
    (node.slots_execution_types.keys + node.slots.map(&:execution_type)).uniq
  end

  def lock_manager_instance(node)
    LockManager.new(type: self.class.to_s, id: node.id, wait: true, expire: 1.minute)
  end
end
