class StatusController < ApplicationController
  def index
    @nodes = Node.all
    @tasks = Task.all

    render :json
  end
end
