class Node
  include Mongoid::Document

  field :hostname, type: String
  field :cores, type: Integer
  field :memory, type: Integer

  has_many :slots

  def populate
    [slots.count - self.cores, 0].max.times.each do
      self.slots.last.destroy
    end

    (self.cores - slots.count).times.each do
      slots << Slot.create
    end

    self.cores
  end

end
