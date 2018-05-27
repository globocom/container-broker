class StatusController < ApplicationController
  layout proc { false if request.xhr? }

  def index
    @nodes = Node.includes(:slots)
    @tasks = Task.includes(slot: :node).to_a
  end
end
