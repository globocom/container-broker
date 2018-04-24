class Task
  include GlobalID::Identification
  include Mongoid::Document

  field :name, type: String
  field :container_id, type: String # do not remove - needed for update status after completion
  field :image, type: String
  field :cmd, type: String
  field :storage_mount, type: String
  field :status, type: String, default: "waiting"
  field :exit_code, type: Integer
  field :error, type: String
  field :error_log, type: String
  field :started_at, type: DateTime
  field :finished_at, type: DateTime
  field :progress, type: String
  field :try_count, type: Integer, default: 0

  belongs_to :slot, optional: true

  def set_error_log(log)
    self.error_log = BSON::Binary.new(log, :generic)
  end

  def retry
    if self.try_count < Settings.task_retry_count
      update(status: "retry", try_count: self.try_count + 1)
    else
      update(status: "error")
    end
  end

  def starting!
    update(status: "starting")
  end

  def retry?
    status == "retry"
  end

  def waiting?
    status == "waiting"
  end

  def waiting!
    update!(status: "waiting")
  end

  def started!
    update(status: "started")
  end

  def completed!
    update(status: "completed")
  end
end
