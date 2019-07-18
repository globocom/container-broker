class TaskSerializer < ActiveModel::Serializer
  attributes :uuid, :status, :exit_code, :error, :try_count,
    :created_at, :started_at, :finished_at, :progress, :seconds_running,
    :tag
end
