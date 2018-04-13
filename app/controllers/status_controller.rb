class StatusController < ApplicationController
  def index
    @nodes = Node.all
    @tasks = Task.all
  end
end
