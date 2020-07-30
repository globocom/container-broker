# frozen_string_literal: true

class KillTaskContainer
  attr_reader :task

  class TaskNotRunningError < StandardError; end

  delegate :node, to: :task

  def initialize(task:)
    @task = task
  end

  def perform
    validate_task_status

    task
      .slot
      .node
      .runner_service(:kill_slot_runner)
      .perform(slot: task.slot)
  end

  private

  def validate_task_status
    raise TaskNotRunningError, "#{task} is not running" unless task.started?
  end
end
