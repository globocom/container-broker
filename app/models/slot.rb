class Slot
  include Mongoid::Document
  field :status, type: String

  belongs_to :node
end
