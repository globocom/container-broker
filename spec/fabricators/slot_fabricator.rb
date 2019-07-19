Fabricator(:slot) do
  node
  status "idle"
end

Fabricator(:slot_idle, from: :slot) do
  status "idle"
  container_id nil
end

Fabricator(:slot_attaching, from: :slot) do
  status "attaching"
  container_id nil
end

Fabricator(:slot_running, from: :slot) do
  status "running"
  container_id { SecureRandom.hex }
end

Fabricator(:slot_releasing, from: :slot) do
  status "releasing"
  container_id { SecureRandom.hex }
end
