class TasksController < ApplicationController
  before_action :set_task, only: [:show]

  def create
    # todo: implementar mecanismo de seleção de slots
    slot = Slot.last

    @task = Task.new(task_params)

    if @task.save
      render json: @task, status: :created
    else
      render json: @task.errors, status: :unprocessable_entity
    end
  end

  def show
    GetTaskStatus.call(task: @task)
    render json: @task
  end

  private
    def set_task
      @task = Task.find(params[:id])
    end

    def task_params
      params.require(:task).permit(:name, :image, :cmd)
    end
end
