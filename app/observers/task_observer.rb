# frozen_string_literal: true

class TaskObserver
  attr_reader :task

  def initialize(task)
    @task = task
  end

  def status_change(_old_value, _new_value); end
end
