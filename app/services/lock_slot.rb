# frozen_string_literal: true

class LockSlot
  attr_reader :execution_type, :node

  def initialize(execution_type:, node: nil)
    @execution_type = execution_type
    @node = node
  end

  def perform
    return unless selected_node

    selected_node
      .slots
      .idle
      .where(execution_type: execution_type)
      .find_one_and_update(
        {
          "$set" => {
            status: "attaching"
          }
        },
        return_document: :after
      )
  end

  private

  def selected_node
    @selected_node ||= node || least_used_node
  end

  def least_used_node
    LeastUsedNode.new(execution_type: execution_type).call
  end
end
