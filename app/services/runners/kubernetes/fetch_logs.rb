# frozen_string_literal: true

module Runners
  module Kubernetes
    class FetchLogs
      HTTP_ERRORS_TO_IGNORE = [
        400
      ].freeze

      def perform(task:)
        task
          .slot
          .node
          .kubernetes_client
          .fetch_pod_logs(pod_name: task.runner_id)
          .body
      rescue KubernetesClient::PodNotFoundError => e
        raise Runners::RunnerIdNotFoundError, e.message
      rescue Kubeclient::HttpError => e
        raise e unless HTTP_ERRORS_TO_IGNORE.include?(e.error_code)

        Rails.logger.error("Error on fetching kubernetes pod logs - #{e.error_code} - #{e.message}")
        ""
      end
    end
  end
end
