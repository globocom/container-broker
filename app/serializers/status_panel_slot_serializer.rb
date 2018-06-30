class StatusPanelSlotSerializer < ActiveModel::Serializer
  attributes :uuid, :name, :container_id, :status
end
