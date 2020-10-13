# frozen_string_literal: true

class TaskSerializer < ActiveModel::Serializer
  attributes :uuid, :status, :exit_code, :error, :try_count,
             :created_at, :started_at, :finished_at, :seconds_running,
             :execution_type
end
