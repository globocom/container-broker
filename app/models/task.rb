# frozen_string_literal: true

class Task
  include GlobalID::Identification
  include Mongoid::Document
  include Mongoid::Uuid
  include MongoidEnumerable
  extend Observable

  field :name, type: String
  field :runner_id, type: String
  field :image, type: String
  field :execution_type, type: String
  field :cmd, type: String
  field :storage_mounts, type: Hash, default: {}
  field :exit_code, type: Integer
  field :error, type: String
  field :logs, type: BSON::Binary
  field :created_at, type: DateTime
  field :started_at, type: DateTime
  field :finished_at, type: DateTime
  field :try_count, type: Integer, default: 0
  field :persist_logs, type: Boolean, default: false
  field :tags, type: Hash, default: {}

  enumerable :status, %w[waiting starting started retry failed completed error], after_change: :status_changed

  belongs_to :slot, optional: true

  index({ created_at: 1 }, expire_after_seconds: 1.month)
  index(tags: 1)
  index(status: 1)
  index(request_id: 1)
  TaskTag.distinct(:name).each { |key| index("tags.#{key}" => 1) }

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
  validate :storage_mount_identifiers_exist

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
    retry!
    RunTasksJob.perform_later(execution_type: execution_type)
  end

  def normalize_tags
    tags.transform_values!(&:to_s)
  end

  def to_s
    "Task #{name} #{uuid} (#{status} runner_id: #{runner_id}) request_id=#{request_id}"
  end

  def generate_runner_id
    prefix = name.gsub("_", "-").parameterize
    random_suffix = SecureRandom.alphanumeric(8).downcase
    max_prefix_size = Constants::Runner::MAX_NAME_SIZE - random_suffix.length - 1

    "#{prefix.truncate(max_prefix_size, omission: "")}-#{random_suffix}"
  end

  def request_id
    tags&.dig("request_id")
  end

  private

  def status_changed(old_value, new_value)
    self.class.observer_instances_for(self).each do |observer|
      observer.status_change(old_value, new_value)
    end
  end

  def storage_mount_identifiers_exist
    valid = Node.pluck(:runner_provider).uniq.all? do |runner|
      (storage_mounts.keys.map(&:to_s) - Settings.storage_mounts[runner].keys.map(&:to_s)).empty?
    end

    return if valid

    errors.add(:storage_mounts, "Storage mounts are invalid")
  end
end
