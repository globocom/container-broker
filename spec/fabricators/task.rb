# frozen_string_literal: true

Fabricator(:task) do
  name "task-name"
  container_id { SecureRandom.hex(32) }
  image "busybox:1.25"
  cmd "sleep 5"
  storage_mount "/tmp"
  ingest_storage_mount "/opt/ef-shared"
  status "waiting"
  slot nil
  exit_code nil
  error nil
  logs nil
  created_at "2018-03-01 18:10:00"
  started_at "2018-03-01 18:10:00"
  finished_at "2018-03-01 18:10:00"
  progress nil
  try_count 0
  tags { { "x" => "y" } }
  execution_type "io"
end

Fabricator(:running_task, from: :task) do
  status :started
end
