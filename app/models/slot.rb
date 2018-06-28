class Slot
  include Mongoid::Document
  include Mongoid::Uuid
  include GlobalID::Identification
  include MongoidEnumerable

  enumerable :status, %w(idle attaching running releasing)

  field :name, type: String
  field :container_id, type: String
  belongs_to :current_task, class_name: "Task", optional: true

  belongs_to :node, optional: true

  after_save do
    if status_changed?
      node.update_usage if node
    end
  end

  def available?
    idle?
  end

  def mark_as_running(current_task:, container_id:)
    update!(current_task: current_task, container_id: container_id)
    running!
  end

  def release
    update!(container_id: nil, current_task: nil)
    idle!
    RunTasksJob.perform_later
  end

  def attaching!
    update!(status: "attaching")
    # node.update_usage
  end

  def attach_to(task:)
    update!(status: "running", current_task: task, container_id: task.container_id)
  end

  def idle!
    update!(status: "idle")
    # node.update_usage
  end

  def running!
    update!(status: "running")
    # node.update_usage
  end

  def releasing!
    update!(status: "releasing")
    # node.update_usage
  end
end
