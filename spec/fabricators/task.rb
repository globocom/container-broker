Fabricator(:task) do
  name "task-name"
  container_id { SecureRandom.hex(32) }
  image "busybox:1.25"
  cmd "sleep 5"
  storage_mount "/tmp"
  status "waiting"
  exit_code nil
  error nil
  logs nil
  created_at "2018-03-01 18:10:00"
  started_at "2018-03-01 18:10:00"
  finished_at "2018-03-01 18:10:00"
  progress nil
  try_count 0
  tags { {"x" => "y"} }
end
