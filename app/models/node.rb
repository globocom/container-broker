# frozen_string_literal: true

class Node
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
  field :runner_config, type: Hash, default: {}

  enumerable :status, %w[available unstable unavailable], default: "unavailable"
  enumerable :runner_provider, %w[docker kubernetes], default: :docker

  has_many :slots

  scope :accepting_new_tasks, -> { where(accept_new_tasks: true, :runner_capacity_reached.in => [nil, false]) }

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
    slots.available
  end

  def destroy_slots
    slots.destroy_all
  end

  def runner_service(service)
    Runners::ServicesFactory.fabricate(runner: runner_provider, service: service)
  end

  def register_error(error)
    Rails.logger.info("Registering error in #{self}: #{error}")

    update!(last_error: "#{error} at #{Time.zone.now}")

    if available?
      unstable!
      Rails.logger.debug("#{self} marked as unstable")
    elsif unstable?
      if unstable_period_expired?
        unavailable!
        Rails.logger.debug("#{self} marked as unavailable because the unstable period has expired (last success was at #{last_success_at}). Migrating all tasks.")
        MigrateTasksFromDeadNodeJob.perform_later(node: self)
      else
        Rails.logger.debug("#{self} still unstable until the limit period be expired (last success was at #{last_success_at})")
      end
    end
  end

  def unstable_period_expired?
    last_success_at && last_success_at < Settings.node_unavailable_after_seconds.seconds.ago
  end

  def register_success
    Rails.logger.debug("Registering success in #{self}")
    update!(last_success_at: Time.zone.now)
  end

  def to_s
    last_success = ", last success at #{last_success_at}" unless available?

    "Node #{name} #{uuid} #{runner_provider} (#{status}#{last_success})"
  end

  def run_with_lock_no_wait(&block)
    LockManager.new(type: self.class.to_s, id: id, wait: false, expire: 5.minutes).lock(&block)
  end

  private

  def execution_types_format
    valid = slots_execution_types
            .keys
            .all? { |execution_type| execution_type.match?(Constants::ExecutionType::FORMAT) }

    errors.add(:slots_execution_types, Constants::ExecutionType::INVALID_FORMAT_MESSAGE) unless valid
  end
end
