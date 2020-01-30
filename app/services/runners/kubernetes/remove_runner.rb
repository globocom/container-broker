# frozen_string_literal: true

module Runners
  module Kubernetes
    class RemoveRunner
      def perform(node:, runner_id:)
        Rails.logger.debug("Deleting pod")
        begin
          node.kubernetes_client.force_delete_pod(pod_name: runner_id)
          Rails.logger.debug("Pod #{runner_id} removed")
        rescue KubernetesClient::PodNotFoundError
          Rails.logger.debug("Pod #{runner_id} already removed")
        end
      end
    end
  end
end
