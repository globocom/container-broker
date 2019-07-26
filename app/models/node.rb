class Node
  include Mongoid::Document
  include Mongoid::Uuid
  include GlobalID::Identification
  include MongoidEnumerable

  field :name, type: String
  field :hostname, type: String
  field :available, type: Boolean, default: true
  field :last_error, type: String
  field :last_success_at, type: DateTime
  field :accept_new_tasks, type: Boolean, default: true
  field :slots_execution_types, type: Hash, default: {}

  enumerable :status, %w(available unstable unavailable), default: "unavailable", after_change: :status_change

  has_many :slots

  def usage_per_execution_type
    NodeUsagePercentagePerExecutionType.new(self).perform
  end

  validates :hostname, presence: true
  validates :slots_execution_types, presence: true

  scope :accepting_new_tasks, -> { where(accept_new_tasks: true) }

  def available_slot_with_execution_type(execution_type)
    available_slots.find_by(execution_type: execution_type)
  end

  def available_slots
    slots.idle
  end

  def destroy_slots
    slots.destroy_all
  end

  def docker_connection
    Docker.logger = Logger.new(STDOUT)
    Docker::Connection.new(hostname, {connect_timeout: 10, read_timeout: 10, write_timeout: 10})
  end

  def register_error(error)
    update!(last_error: error)
    if last_success_at && last_success_at < Settings.node_unavailable_after_seconds.seconds.ago
      unavailable!
      MigrateTasksFromDeadNodeJob.perform_later(node: self)
    else
      unstable!
    end
  end

  def update_last_success
    update!(last_success_at: Time.zone.now)
  end
end
