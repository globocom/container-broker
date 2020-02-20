# frozen_string_literal: true

class Slot
  include Mongoid::Document
  include Mongoid::Uuid
  include GlobalID::Identification
  include MongoidEnumerable

  enumerable :status, %w[idle attaching running releasing]

  field :name, type: String
  field :execution_type, type: String
  field :runner_id, type: String
  belongs_to :current_task, class_name: "Task", optional: true

  belongs_to :node, optional: true

  index(runner_id: 1)
  index(node_id: 1)
  index(execution_type: 1, status: 1)

  validates :execution_type, presence: true
  validates :execution_type, format: {
    with: Constants::ExecutionType::FORMAT,
    message: Constants::ExecutionType::INVALID_FORMAT_MESSAGE
  }

  scope :working, -> { where(:status.in => %w[attaching running releasing]) }

  def available?
    idle?
  end

  def mark_as_running(current_task:, runner_id:)
    update!(status: :running, current_task: current_task, runner_id: runner_id)
  end

  def release
    update!(status: :idle, runner_id: nil, current_task: nil)
    RunTasksJob.perform_later(execution_type: execution_type)
  end

  def to_s
    "Slot #{name} #{uuid} (#{status} runner_id: #{runner_id})"
  end
end
