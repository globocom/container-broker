# frozen_string_literal: true

class StatusController < ApplicationController
  layout proc { false if request.xhr? }
  LIMIT_TASKS = 200

  def index
  end

  def nodes
    render json: Node.includes(:slots), each_serializer: StatusPanelNodeSerializer
  end

  def tasks
    @tasks = Task
      .only(Task.attribute_names - %w[logs])
      .includes(:slot)
      .order_by("created_at" => "desc")
      .batch_size(LIMIT_TASKS)
      .limit(LIMIT_TASKS)

    @tasks = @tasks.where(status: params[:status]) if params[:status].present?
    if params[:tags]
      params.require(:tags).each do |tag, value|
        @tasks = @tasks.where("tags.#{tag}" => value.to_s)
      end
    end

    render json: @tasks, each_serializer: StatusPanelTaskSerializer
  end

  def tags
    @tags = TaskTag.pluck(:name)
    render json: @tags
  end

  def task_statuses
    render json: Task.all_status
  end

  def tag_values
    @tag = TaskTag.find_by!(name: params[:tag_name])
    render json: @tag.values.take(50)
  end

  def retry_task
    @task = Task.find_by!(uuid: params[:uuid])
    @task.force_retry!

    head :ok
  end
end
