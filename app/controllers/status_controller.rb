class StatusController < ApplicationController
  def index
    @nodes = Node.includes(:slots)
    @tasks = Task.includes(slot: :node)
  end
end
