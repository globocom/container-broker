# frozen_string_literal: true

class TasksController < ApplicationController
  before_action :set_task, only: %i[show logs mark_as_error kill_container]
  before_action :set_request_id, only: %i[create]

  def create
    @task = Task.new(task_params)

    if @task.save
      Metrics.new("tasks").count(
        task_id: @task.id,
        name: @task&.name,
        status: @task.status
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
    render json: { logs: @task.get_logs&.encode("utf-8", undef: :replace, replace: "?") }
  end

  def clear_errors
    Task.error.destroy
    head :ok
  end

  def mark_as_error
    if @task.failed?
      @task.error!

      head :ok
    else
      render json: { message: "Task must have failed status to be marked as error" }, status: :unprocessable_entity
    end
  end

  def kill_container
    KillTaskContainer.new(task: @task).perform

    head :ok
  rescue KillTaskContainer::TaskNotRunningError => e
    render json: { message: e.message }, status: :bad_request
  end

  private

  def set_task
    @task = Task.find_by!(uuid: params[:uuid])
  end

  def task_params
    params.require(:task).permit(
      :name,
      :image,
      :cmd,
      :storage_mount,
      :ingest_storage_mount,
      :persist_logs,
      :execution_type,
      tags: {}
    )
  end

  def set_request_id
    params[:task][:tags] ||= {}
    params[:task][:tags][:request_id] = request.request_id
  end
end
