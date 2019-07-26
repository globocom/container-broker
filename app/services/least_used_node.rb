class LeastUsedNode
  def initialize(execution_type:)
    @execution_type = execution_type
  end

  def call
    available_nodes_ordered_by_usage.first
  end

  private

  def available_nodes_ordered_by_usage
    Node
      .includes(:slots)
      .available
      .select{ |node| node.available_slot_with_execution_type(@execution_type).present? }
      .sort_by do |node|
        slots = node.slots.where(execution_type: @execution_type)

        SlotsUsagePercentage.new(slots).perform
      end
  end
end
