# frozen_string_literal: true

class Node
  class InvalidRunner < StandardError; end
  class NodeConnectionError < StandardError; end

  include Mongoid::Document
  include Mongoid::Uuid
  include Mongoid::Timestamps
  include GlobalID::Identification
  include MongoidEnumerable

  field :name, type: String
  field :hostname, type: String
  field :last_error, type: String
  field :last_success_at, type: DateTime
  field :accept_new_tasks, type: Boolean, default: true
  field :runner_capacity_reached, type: Boolean, default: false
  field :slots_execution_types, type: Hash, default: {}

  enumerable :status, %w[available unstable unavailable], default: "unavailable", after_change: :status_change
  enumerable :runner, %w[docker kubernetes], default: :docker

  has_many :slots
  embeds_one :kubernetes_config

  scope :accepting_new_tasks, -> { where(accept_new_tasks: true, :runner_capacity_reached.in => [nil, false]) }

  validates :hostname, presence: true
  validates :slots_execution_types, presence: true
  validate :execution_types_format

  validates :kubernetes_config, presence: true, if: :kubernetes?
  validates :kubernetes_config, absence: true, unless: :kubernetes?

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
    raise(InvalidRunner, "Node must be a docker runner") unless docker?

    ::Docker::Connection.new(hostname, connect_timeout: 10, read_timeout: 10, write_timeout: 10)
  end

  def kubernetes_client
    raise(InvalidRunner, "Node must be a kubernetes runner") unless kubernetes?

    KubernetesClient.new(
      uri: hostname,
      bearer_token: kubernetes_config.bearer_token,
      namespace: kubernetes_config.namespace
    )
  end

  def runner_service(service)
    Runners::ServicesFactory.fabricate(runner: runner, service: service)
  end

  def register_error(error)
    Rails.logger.info("Registering error in #{self}: #{error}")

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

  def run_with_lock_no_wait
    LockManager.new(type: self.class.to_s, id: id, wait: false, expire: 5.minutes).lock do
      yield
    end
  end

  private

  def execution_types_format
    valid = slots_execution_types
            .keys
            .all? { |execution_type| execution_type.match?(Constants::ExecutionType::FORMAT) }

    errors.add(:slots_execution_types, Constants::ExecutionType::INVALID_FORMAT_MESSAGE) unless valid
  end
end
