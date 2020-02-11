# frozen_string_literal: true

module Runners
  module Kubernetes
    class FetchExecutionInfo
      def perform(task:)
        pod = CreateClient.new.perform(node: task.slot.node).fetch_pod(pod_name: task.runner_id)

        CreateExecutionInfo.new.perform(pod: pod)
      rescue KubernetesClient::PodNotFoundError => e
        raise Runners::RunnerIdNotFoundError, e.message
      end
    end
  end
end
