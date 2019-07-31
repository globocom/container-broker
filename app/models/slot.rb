class Slot
  include Mongoid::Document
  include Mongoid::Uuid
  include GlobalID::Identification
  include MongoidEnumerable

  enumerable :status, %w(idle attaching running releasing)

  field :name, type: String
  field :execution_type, type: String
  field :container_id, type: String
  belongs_to :current_task, class_name: "Task", optional: true

  belongs_to :node, optional: true

  validates :execution_type, presence: true
  validates :execution_type, format: {
    with: Constants::REGEX_TO_VALIDATE_EXECUTION_TYPE,
    message: "only allows lowercase letters, numbers and hyphen symbol"
  }

  scope :working, -> { where(:status.in => %w[attaching running releasing]) }

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

  def attach_to(task:)
    update!(status: "running", current_task: task, container_id: task.container_id)
  end

  def to_s
    "Slot #{name} #{uuid} (#{status})"
  end
end
