# frozen_string_literal: true

class LeastUsedNode
  attr_reader :execution_type

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
    @nodes_by_usage ||=
      nodes
      .filter { |node| slots(node.id).to_a.filter(&:available?).any? }
      .group_by { |node| SlotsUsagePercentage.new(slots(node.id)).perform }
  end

  def nodes
    @nodes ||=
      Node
      .accepting_new_tasks
      .available
  end

  def slots(node_id)
    @slots ||=
      Slot
      .only(:id, :node_id, :status)
      .where(:node_id.in => nodes.map(&:id))
      .where(execution_type: execution_type)
      .group_by(&:node_id)

    @slots[node_id]
  end
end
