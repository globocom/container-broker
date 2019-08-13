# frozen_string_literal: true

Fabricator(:node) do
  name { sequence(:node_index) {|index| "n#{index}" }}
  hostname { sequence(:node_index) {|index| "worker#{index}.test" }}
  status "available"
  accept_new_tasks true
  slots_execution_types { { io: 10, cpu: 5 } }
end
