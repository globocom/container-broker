class Node
  include Mongoid::Document

  field :hostname, type: String
  field :cores, type: Integer
  field :memory, type: Integer

  has_many :slots
end
