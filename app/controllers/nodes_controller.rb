class NodesController < ApplicationController
  before_action :load_node, only: %i[update destroy accept_new_tasks reject_new_tasks kill_containers]

  def index
    render json: Node.all, each_serializer: NodeSerializer
  end

  def create
    @node = Node.create!(node_params)

    FriendlyNameNodes.new.perform
    AdjustNodeSlotsJob.perform_later(node: @node)

    render json: @node, status: :created, serializer: NodeSerializer
  end

  def update
    @node.update!(node_params.slice(:slots_execution_types))
    AdjustNodeSlotsJob.perform_later(node: @node)

    head :ok
  end

  def destroy
    DeleteNode.new(node: @node).perform
    FriendlyNameNodes.new.perform

    head :ok
  rescue DeleteNode::NodeWithRunningSlotsError
    head :not_acceptable
  end

  def reject_new_tasks
    NodeTaskAcceptance.new(node: @node).reject!

    head :ok
  end

  def accept_new_tasks
    NodeTaskAcceptance.new(node: @node).accept!

    head :ok
  end

  def kill_containers
    KillNodeContainers.new(node: @node).perform

    head :ok
  end

  private

  def load_node
    @node = Node.find_by(uuid: params[:uuid])
  end

  def node_params
    params.require(:node).permit(:hostname, slots_execution_types: {})
  end
end
