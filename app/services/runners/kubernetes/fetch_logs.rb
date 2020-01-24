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
          .fetch_job_logs(job_name: task.container_id)
          .body
      rescue Kubeclient::HttpError => e
        raise e unless HTTP_ERRORS_TO_IGNORE.include?(e.error_code)

        Rails.logger.error("Error on fetching kubernetes pod logs - #{e.error_code} - #{e.message}")
        nil
      end
    end
  end
end
