# frozen_string_literal: true

class LockTask
  attr_reader :execution_type

  def initialize(execution_type:)
    @execution_type = execution_type
  end

  def perform
    task = all_pending
           .find_one_and_update(
             {
               "$set" => { status: "starting" }
             }, return_document: :after
           )
    return unless task

    task.reload

    persist_metrics(task)

    task
  end

  def any_pending?
    all_pending.any?
  end

  private

  def all_pending
    Task
      .where(execution_type: execution_type)
      .where(:status.in => %w[waiting retry])
  end

  def persist_metrics(task)
    Metrics.new("tasks").count(
      task_id: task.id,
      name: task&.name,
      status: task.status
    )
  end
end
