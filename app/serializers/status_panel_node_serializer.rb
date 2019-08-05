class StatusPanelNodeSerializer < ActiveModel::Serializer
  attributes :uuid, :name, :hostname, :status, :last_error, :last_success_at,
    :usage_per_execution_type, :slots_execution_types, :accept_new_tasks

  has_many :slots, serializer: StatusPanelSlotSerializer
end
