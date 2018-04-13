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

    self.cores
  end

  def docker_connection
    Docker::Connection.new(self.hostname, {})
  end

  def update_usage
    self.update!(usage_percent: (available_slots.count / slots.count).to_i * 100)
  end

end
