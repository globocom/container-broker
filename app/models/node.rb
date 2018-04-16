class Node
  include Mongoid::Document
  include GlobalID::Identification

  field :hostname, type: String
  field :cores, type: Integer
  field :memory, type: Integer
  field :available, type: Boolean
  field :usage_percent, type: Integer

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

    self.cores
  end

  def docker_connection
    Docker.options[:read_timeout] = 5
    Docker::Connection.new(self.hostname, {})
  end

  def update_usage
    usage = (1.0 - available_slots.count.to_f / slots.count) * 100
    self.update!(usage_percent: usage)
  end

end
