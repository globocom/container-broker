class Node
  include Mongoid::Document
  include GlobalID::Identification

  field :name, type: String
  field :hostname, type: String
  field :cores, type: Integer, default: 0
  field :memory, type: Integer, default: 0
  field :available, type: Boolean, default: true
  field :usage_percent, type: Integer
  field :last_error, type: String

  has_many :slots

  def self.available
    Node.where(available: true)
  end

  def find_available_slot
    available_slots.first
  end

  def available_slots
    slots.to_a.select(&:available?)
  end

  def populate
    [slots.count - cores, 0].max.times.each do
      reload
      slots.last.destroy!
    end

    (cores - slots.count).times.each do
      slots << Slot.create!
    end

    update_usage

    FriendlyNameNodes.new.call

    cores
  end

  def docker_connection
    Docker.logger = Logger.new(STDOUT)
    Docker::Connection.new(hostname, {connect_timeout: 10, read_timeout: 10, write_timeout: 10})
  end

  def update_usage
    usage = (1.0 - available_slots.count.to_f / slots.count) * 100
    update!(usage_percent: usage)
  end

  def unavailable!(error: nil)
    update!(available: false, last_error: error)
  end

  def available!
    update!(available: true, last_error: nil)
  end
end
