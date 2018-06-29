class StatusController < ApplicationController
  layout proc { false if request.xhr? }

  def index
    @nodes = Node.includes(:slots)
    @tasks = Task.includes(slot: :node).to_a
  end

  def nodes
    render json: Node.all, include: :slots
  end

  def tasks
    render json: Task.all.limit(1000)
  end
end
