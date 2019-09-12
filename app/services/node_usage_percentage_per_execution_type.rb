# frozen_string_literal: true

class NodeUsagePercentagePerExecutionType
  def initialize(node)
    @node = node
  end

  def perform
    execution_type_groups.map do |execution_type_group|
      {
        execution_type: execution_type_group[0],
        usage_percent: SlotsUsagePercentage.new(execution_type_group[1]).perform
      }
    end
  end

  private

  def execution_type_groups
    @node.slots.group_by(&:execution_type)
  end
end
