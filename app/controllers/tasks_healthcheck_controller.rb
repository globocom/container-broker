# frozen_string_literal: true

class TasksHealthcheckController < ApplicationController
  def index
    render json: {
      status: status,
      failed_tasks_count: failed_tasks_count
    }
  end

  private

  def failed_tasks_count
    @failed_tasks_count ||= Task.failed.count
  end

  def tasks_failed?
    failed_tasks_count > 0
  end

  def status
    if tasks_failed?
      "FAILING"
    else
      "WORKING"
    end
  end
end
