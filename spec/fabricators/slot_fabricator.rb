# frozen_string_literal: true

Fabricator(:slot) do
  node
  status "available"
  execution_type "execution-type"
end

Fabricator(:slot_available, from: :slot) do
  status "available"
  runner_id nil
  execution_type "execution-type"
end

Fabricator(:slot_attaching, from: :slot) do
  status "attaching"
  runner_id nil
  execution_type "execution-type"
end

Fabricator(:slot_running, from: :slot) do
  status "running"
  runner_id { SecureRandom.hex }
  execution_type "execution-type"
end

Fabricator(:slot_releasing, from: :slot) do
  status "releasing"
  runner_id { SecureRandom.hex }
  execution_type "execution-type"
end
