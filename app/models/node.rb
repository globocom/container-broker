# frozen_string_literal: true

class Node
  include Mongoid::Document
  include Mongoid::Uuid
  include Mongoid::Timestamps
  include GlobalID::Identification
  include MongoidEnumerable

  field :name, type: String
  field :hostname, type: String
  field :available, type: Boolean, default: true
  field :last_error, type: String
  field :last_success_at, type: DateTime
  field :accept_new_tasks, type: Boolean, default: true
  field :slots_execution_types, type: Hash, default: {}

  enumerable :status, %w[available unstable unavailable], default: "unavailable", after_change: :status_change
  enumerable :runner, %w[docker kubernetes], default: :docker

  has_many :slots

  scope :accepting_new_tasks, -> { where(accept_new_tasks: true) }

  validates :hostname, presence: true
  validates :slots_execution_types, presence: true
  validate :execution_types_format

  def usage_per_execution_type
    NodeUsagePercentagePerExecutionType.new(self).perform
  end

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
    ::Docker::Connection.new(hostname, connect_timeout: 10, read_timeout: 10, write_timeout: 10)
  end

  def register_error(error)
    Rails.logger.info("Error connecting to node #{name}: #{error}")

    update!(last_error: error)

    if available?
      unstable!
    elsif unstable? && unstable_period_expired?
      unavailable!
      MigrateTasksFromDeadNodeJob.perform_later(node: self)
    end
  end

  def unstable_period_expired?
    last_success_at && last_success_at < Settings.node_unavailable_after_seconds.seconds.ago
  end

  def update_last_success
    update!(last_success_at: Time.zone.now)
  end

  def to_s
    "Node #{name} #{uuid} #{runner}"
  end

  private

  def execution_types_format
    valid = slots_execution_types
            .keys
            .all? { |execution_type| execution_type.match?(Constants::ExecutionType::FORMAT) }

    errors.add(:slots_execution_types, Constants::ExecutionType::INVALID_FORMAT_MESSAGE) unless valid
  end
end
