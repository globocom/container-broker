class TasksHealthcheckController < ApplicationController
  def index
    render json: {
      status: status,
      failed_tasks: invalid_tasks.map{ |task| TaskHealthcheckSerializer.new(task) },
    }
  end

  def invalid_tasks
    @invalid_tasks ||= Task.error
  end

  def tasks_invalid?
    invalid_tasks.to_a.any?
  end

  def status
    if tasks_invalid?
      "FAILING"
    else
      "WORKING"
    end
  end
end
