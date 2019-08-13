# frozen_string_literal: true

class TaskHealthcheckSerializer < ActiveModel::Serializer
  attributes :uuid, :status, :error, :created_at, :started_at, :finished_at, :execution_type
end
