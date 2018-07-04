class StatusController < ApplicationController
  layout proc { false if request.xhr? }

  def index
    @nodes = Node.includes(:slots)
    @tasks = Task.includes(slot: :node).to_a
  end

  def nodes
    render json: Node.includes(:slots) , each_serializer: StatusPanelNodeSerializer
  end

  def tasks
    @tasks  = Task.all
    if params[:tags]
      params.require(:tags).each do |tag, value|
        @tasks = @tasks.where("tags.#{tag}" => value.to_s)
      end
    end
    render json: @tasks.limit(1000), each_serializer: StatusPanelTaskSerializer
  end

  def tags
    @tags = TaskTag.pluck(:name)
    render json: @tags
  end

  def tag_values
    @tag = TaskTag.find_by(name: params[:tag_name])
    render json: @tag.values.take(50)
  end
end
