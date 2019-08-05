class NodeSerializer < ActiveModel::Serializer
  attributes :uuid, :hostname, :status, :accept_new_tasks, :slots_execution_types
end
