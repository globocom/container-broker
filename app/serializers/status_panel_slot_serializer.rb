class StatusPanelSlotSerializer < ActiveModel::Serializer
  attributes :uuid, :name, :container_id, :status, :execution_type
end
