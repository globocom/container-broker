class TaskHealthcheckSerializer < ActiveModel::Serializer
  attributes :uuid, :status, :error, :created_at, :started_at, :finished_at, :execution_type, :node_name

  def node_name
    object&.slot.node.name
  end
end
