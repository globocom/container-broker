class NodeHealthcheckSerializer < ActiveModel::Serializer
  attributes :uuid, :name, :hostname, :status, :last_error, :created_at, :updated_at
end
