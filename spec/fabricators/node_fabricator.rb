# frozen_string_literal: true

Fabricator(:node) do
  name { sequence(:node_index) { |index| "n#{index}" } }
  hostname { sequence(:node_index) { |index| "http://worker#{index}.test" } }
  status "available"
  accept_new_tasks true
  slots_execution_types { { io: 10, cpu: 5 } }
  runner_capacity_reached false
end

Fabricator(:node_docker, from: :node)

Fabricator(:node_unstable, from: :node) do
  status "unstable"
end

Fabricator(:node_kubernetes, from: :node) do
  runner_provider :kubernetes
  runner_config do
    {
      "namespace" => "videos-ingest",
      "bearer_token" => SecureRandom.base64,
      "nfs_path" => "/dev/nfs",
      "nfs_server" => "nfs.test",
      "node_selector" => "ef"
    }
  end
end
