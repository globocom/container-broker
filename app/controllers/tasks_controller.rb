class TasksController < ApplicationController
  before_action :set_task, only: [:show, :logs, :mark_as_resolved]

  def create
    @task = Task.new(task_params)

    if @task.save
      Metrics.new("tasks").count(
        task_id: @task.id,
        name: @task&.name,
        status: @task.status,
      )

      render json: @task
    else
      render json: @task.errors, status: :unprocessable_entity
    end
  end

  def show
    render json: @task
  end

  def logs
    render json: { logs: @task.get_logs }
  end

  def clear_failed
    Task.error.delete
    head :ok
  end

  def mark_as_resolved
    @task.resolved!
  end

  private
    def set_task
      @task = Task.find_by!(uuid: params[:uuid])
    end

    def task_params
      params.require(:task).permit(:name, :image, :cmd, :storage_mount, :persist_logs, :execution_type, tags: {})
    end
end
