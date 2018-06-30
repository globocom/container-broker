class StatusController < ApplicationController
  layout proc { false if request.xhr? }

  def index
    @nodes = Node.includes(:slots)
    @tasks = Task.includes(slot: :node).to_a
  end

  def nodes
    render json: Node.all, each_serializer: StatusPanelNodeSerializer
  end

  def tasks
    render json: Task.all.limit(1000), each_serializer: StatusPanelTaskSerializer
  end
end
