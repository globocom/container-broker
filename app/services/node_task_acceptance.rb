class NodeTaskAcceptance
  attr_reader :node

  def initialize(node:)
    @node = node
  end

  def accept!
    @node.update!(accept_new_tasks: true)
    RunTasksJob.perform_later
  end

  def reject!
    @node.update!(accept_new_tasks: false)
  end
end
