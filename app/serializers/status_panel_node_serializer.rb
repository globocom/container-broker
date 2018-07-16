class StatusPanelNodeSerializer < ActiveModel::Serializer
  attributes :uuid, :name, :hostname, :cores, :memory, :available, :usage_percent, :last_error
  has_many :slots, serializer: StatusPanelSlotSerializer
end
