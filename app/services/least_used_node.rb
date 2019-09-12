# frozen_string_literal: true

class LeastUsedNode
  def initialize(execution_type:)
    @execution_type = execution_type
  end

  def call
    least_used_nodes&.sample
  end

  private

  def least_used_nodes
    nodes_by_usage[nodes_by_usage.keys.min]
  end

  def nodes_by_usage
    @nodes_by_usage ||= Node
                        .accepting_new_tasks
                        .includes(:slots)
                        .available
                        .select { |node| node.available_slot_with_execution_type(@execution_type).present? }
                        .group_by do |node|
      slots = node.slots.where(execution_type: @execution_type)
      SlotsUsagePercentage.new(slots).perform
    end
  end
end
