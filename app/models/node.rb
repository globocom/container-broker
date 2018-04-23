class Node
  include Mongoid::Document
  include GlobalID::Identification

  field :name, type: String
  field :hostname, type: String
  field :cores, type: Integer
  field :memory, type: Integer
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
    [slots.count - self.cores, 0].max.times.each do
      self.slots.last.destroy!
    end

    (self.cores - slots.count).times.each do
      slots << Slot.create!
    end

    update_usage

    FriendlyNameNodes.new.call

    self.cores
  end

  def docker_connection
    Docker::Connection.new(self.hostname, {connect_timeout: 10, read_timeout: 10, write_timeout: 10})
  end

  def update_usage
    usage = (1.0 - available_slots.count.to_f / slots.count) * 100
    self.update!(usage_percent: usage)
  end

  def mark_as_unavailable(error: nil)
    self.update(available: false, last_error: error)
  end

end
