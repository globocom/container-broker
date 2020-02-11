# frozen_string_literal: true

class Task
  include GlobalID::Identification
  include Mongoid::Document
  include Mongoid::Uuid
  include MongoidEnumerable

  field :name, type: String
  field :runner_id, type: String
  field :image, type: String
  field :execution_type, type: String
  field :cmd, type: String
  field :storage_mount, type: String
  field :ingest_storage_mount, type: String
  field :exit_code, type: Integer
  field :error, type: String
  field :logs, type: BSON::Binary
  field :created_at, type: DateTime
  field :started_at, type: DateTime
  field :finished_at, type: DateTime
  field :progress, type: String
  field :try_count, type: Integer, default: 0
  field :persist_logs, type: Boolean, default: false
  field :tags, type: Hash, default: {}

  enumerable :status, %w[waiting starting started retry failed completed error]

  belongs_to :slot, optional: true

  index({ created_at: 1 }, expire_after_seconds: 1.month)
  index(tags: 1)
  index(status: 1)
  index("tags.api_id" => 1)
  index("tags.event_id" => 1)

  before_validation :normalize_tags
  before_create { |task| task.created_at = Time.zone.now }
  after_create do
    RunTasksJob.perform_later(execution_type: execution_type)
    AddTaskTagsJob.perform_later(task: self)
  end

  validates :name, :image, :cmd, :execution_type, presence: true
  validates :execution_type, format: {
    with: Constants::ExecutionType::FORMAT,
    message: Constants::ExecutionType::INVALID_FORMAT_MESSAGE
  }

  # TODO: Remove this getter after first deploy
  def runner_id
    return super if Rails.env.test?

    super || attributes["runner_id"]
  end

  def set_logs(logs)
    self.logs = BSON::Binary.new(logs.dup, :generic)
  end

  def get_logs
    if started?
      slot.node.runner_service(:fetch_logs).perform(task: self)
    else
      logs.try(:data)
    end
  end

  def mark_as_started!(runner_id:, slot:)
    update!(started_at: Time.zone.now, runner_id: runner_id, slot: slot)

    started!
  end

  def mark_as_retry(error: nil)
    update!(error: error)

    if try_count < Settings.task_retry_count
      update(try_count: try_count + 1, slot: nil, runner_id: nil)
      retry!
      RunTasksJob.perform_later(execution_type: execution_type)
    else
      failed!
    end
  end

  def milliseconds_waiting
    if started? || completed? || failed?
      calculate_millisecond_span(created_at, started_at)
    else
      calculate_millisecond_span(created_at, Time.zone.now.to_datetime)
    end
  end

  def milliseconds_running
    if completed? || failed?
      calculate_millisecond_span(started_at, finished_at)
    elsif started?
      calculate_millisecond_span(started_at, Time.zone.now.to_datetime)
    end
  end

  def seconds_running
    milliseconds_running&.div(1000)
  end

  def calculate_millisecond_span(start, finish)
    ((finish - start) * 1.day.in_milliseconds).to_i if finish.present? && start.present?
  end

  def force_retry!
    update(try_count: 0)
    waiting!
    RunTasksJob.perform_later(execution_type: execution_type)
  end

  def normalize_tags
    tags.transform_values!(&:to_s)
  end

  def to_s
    "Task #{name} #{uuid} (#{status} runner_id: #{runner_id})"
  end

  def generate_runner_id
    prefix = name.gsub("_", "-").parameterize
    random_suffix = SecureRandom.alphanumeric(8).downcase

    "#{prefix}-#{random_suffix}"
  end
end
