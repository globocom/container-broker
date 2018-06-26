class TasksController < ApplicationController
  before_action :set_task, only: [:show, :error_log]

  def create
    # todo: implementar mecanismo de seleção de slots
    slot = Slot.last

    @task = Task.new(task_params)

    if @task.save
      render json: @task, except: :_id, status: :created
    else
      render json: @task.errors, status: :unprocessable_entity
    end
  end

  def show
    render json: @task, except: :_id
  end

  def error_log
    render plain: @task.error_log
  end

  private
    def set_task
      @task = Task.find_by(uuid: params[:uuid])
    end

    def task_params
      params.require(:task).permit(:name, :image, :cmd, :storage_mount)
    end
end
