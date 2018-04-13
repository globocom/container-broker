class Slot
  include Mongoid::Document
  include GlobalID::Identification

  field :status, type: String
  field :container_id, type: String
  belongs_to :current_task, class_name: "Task", optional: true

  belongs_to :node, optional: true

  after_initialize do |slot|
    slot.status ||= "idle"
  end

  def available?
    status == "idle"
  end

  def release
    self.update!(status: "idle", container_id: nil, current_task: nil)
  end

  def attaching!
    self.update!(status: "attaching")
  end

  def attach_to(task:)
    self.update!(status: "running", current_task: task, container_id: task.container_id)
  end
end
