class NodeSerializer < ActiveModel::Serializer
  attributes :uuid, :hostname, :status, :accept_new_tasks
end
