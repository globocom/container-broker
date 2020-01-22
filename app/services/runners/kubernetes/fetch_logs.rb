# frozen_string_literal: true

module Runners
  module Kubernetes
    class FetchLogs
      def perform(task:)
        task
          .slot
          .node
          .kubernetes_client
          .fetch_job_logs(job_name: task.container_id)
          .body
      end
    end
  end
end
