class StatusPanelNodeSerializer < ActiveModel::Serializer
  attributes :uuid, :name, :hostname, :cores, :memory, :status, :last_error, :last_success_at
  has_many :slots, serializer: StatusPanelSlotSerializer
end
