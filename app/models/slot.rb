class Slot
  include Mongoid::Document
  include GlobalID::Identification

  field :name, type: String
  field :status, type: String, default: "idle"
  field :container_id, type: String
  belongs_to :current_task, class_name: "Task", optional: true

  belongs_to :node, optional: true

  def available?
    idle?
  end

  def release
    update!(container_id: nil, current_task: nil)
    idle!
  end

  def attaching!
    update!(status: "attaching")
    node.update_usage
  end

  def attaching?
    status == "attaching"
  end

  def attach_to(task:)
    update!(status: "running", current_task: task, container_id: task.container_id)
  end

  def idle?
    status == "idle"
  end

  def idle!
    update!(status: "idle")
    node.update_usage
  end

  def running?
    status == "running"
  end

  def running!
    update!(status: "running")
    node.update_usage
  end

  def releasing?
    status == "releasing"
  end

  def releasing!
    update!(status: "releasing")
    node.update_usage
  end
end
