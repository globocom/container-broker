# frozen_string_literal: true

module Runners
  module Kubernetes
    class FetchLogs
      def perform(task:)
        task
          .slot
          .node
          .kubernetes_client
          .fetch_pod_logs(pod_name: task.runner_id)
      rescue KubernetesClient::PodNotFoundError => e
        raise Runners::RunnerIdNotFoundError, e.message
      rescue KubernetesClient::LogsNotFoundError
        Rails.logger.error("Error on fetching kubernetes pod logs")

        "Logs not found"
      end
    end
  end
end
