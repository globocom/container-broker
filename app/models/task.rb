class Task
  include GlobalID::Identification
  include Mongoid::Document
  include Mongoid::Uuid
  include MongoidEnumerable

  field :name, type: String
  field :container_id, type: String # do not remove - needed for update status after completion
  field :image, type: String
  field :cmd, type: String
  field :storage_mount, type: String
  enumerable :status, %w(waiting starting started running retry error completed)
  field :exit_code, type: Integer
  field :error, type: String
  field :logs, type: String
  field :created_at, type: DateTime
  field :started_at, type: DateTime
  field :finished_at, type: DateTime
  field :progress, type: String
  field :try_count, type: Integer, default: 0
  field :tags, type: Hash, default: Hash.new

  belongs_to :slot, optional: true

  index({created_at: 1}, {expire_after_seconds: 1.month})
  index({tags: 1})

  before_create {|task| task.created_at = Time.zone.now }
  after_create do
    RunTasksJob.perform_later
    AddTaskTagsJob.perform_later(task: self)
  end

  validates :name, :image, :cmd, presence: true

  def set_logs(logs)
    self.logs = BSON::Binary.new(logs, :generic)
  end

  def mark_as_started!
    update!(started_at: Time.zone.now)

    started!
  end

  def retry
    if self.try_count < Settings.task_retry_count
      update(try_count: self.try_count + 1)
      retry!
      RunTasksJob.perform_later
    else
      error!
    end
  end

  def seconds_running
    ((finished_at - started_at) * 1.day.seconds).to_i if completed?
  end

  def force_retry!
    update(try_count: 0)
    waiting!
    RunTasksJob.perform_later
  end
end
