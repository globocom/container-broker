class Task
  include GlobalID::Identification
  include Mongoid::Document

  field :name, type: String
  field :container_id, type: String # do not remove - needed for update status after completion
  field :image, type: String
  field :cmd, type: String
  field :status, type: String
  field :exit_code, type: Integer
  field :error, type: String
  field :error_log, type: BSON::Binary
  field :started_at, type: DateTime
  field :finished_at, type: DateTime
  field :progress, type: String

  belongs_to :slot, optional: true

  after_initialize do |task|
    task.status ||= "waiting"
  end

  def set_error_log(log)
    self.error_log = BSON::Binary.new(log, :generic)
    # self.error_log = log
  end
end
