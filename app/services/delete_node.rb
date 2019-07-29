class DeleteNode
  class NodeWithRunningSlotsError < StandardError; end

  attr_reader :node

  def initialize(node:)
    @node = node
  end

  def perform
    if node.accept_new_tasks
      was_accepting_new_tasks = true
      NodeAcceptTasksService.new(node: node).reject!
    end

    if node.slots.working.any?
      NodeAcceptTasksService.new(node: node).accept! if was_accepting_new_tasks
      raise NodeWithRunningSlotsError
    else
      node.destroy!
    end
  end
end
