# frozen_string_literal: true

module Runners
  module Kubernetes
    class FetchExecutionInfo
      def perform(task:)
        pod = task.slot.node.kubernetes_client.fetch_pod(job_name: task.container_id)

        CreateExecutionInfo.new.perform(pod: pod)
      end
    end
  end
end
