class LockTask
  attr_reader :execution_type

  def initialize(execution_type:)
    @execution_type = execution_type
  end

  def call
    if first_pending
      task = nil
      LockManager.new(type: "get_free_task", id: "", expire: 30.seconds, wait: true).lock do
        task = first_pending
        task.starting! if task

        Metrics.new("tasks").count(
          id: task.id,
          name: task&.name,
          status: task.status,
        )
      end

      task
    end
  end

  def first_pending
    all_pending.first
  end

  private

  def all_pending
    Task
      .where(execution_type: execution_type)
      .where(:status.in => %w[waiting retry])
  end
end
