class TasksHealthcheckController < ApplicationController
  def index
    render json: {
      status: status,
      failed_tasks: failed_tasks.map{ |task| TaskHealthcheckSerializer.new(task) },
    }
  end

  private

  def failed_tasks
    @failed_tasks ||= Task.error
  end

  def tasks_failed?
    failed_tasks.to_a.any?
  end

  def status
    if tasks_failed?
      "FAILING"
    else
      "WORKING"
    end
  end
end
