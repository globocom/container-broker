# frozen_string_literal: true

class Slot
  include Mongoid::Document
  include Mongoid::Uuid
  include GlobalID::Identification
  include MongoidEnumerable

  enumerable :status, %w[idle attaching running releasing]

  field :name, type: String
  field :execution_type, type: String
  field :container_id, type: String
  belongs_to :current_task, class_name: "Task", optional: true

  belongs_to :node, optional: true

  validates :execution_type, presence: true
  validates :execution_type, format: {
    with: Constants::ExecutionType::FORMAT,
    message: Constants::ExecutionType::INVALID_FORMAT_MESSAGE
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
    RunTasksJob.perform_later(execution_type: execution_type)
  end

  def to_s
    "Slot #{name} #{uuid} (#{status})"
  end
end
