# frozen_string_literal: true

module Runners
  module Kubernetes
    class RemoveRunner
      def perform(node:, runner_id:)
        Rails.logger.debug("Deleting job")
        begin
          node.kubernetes_client.delete_job(job_name: runner_id)
          Rails.logger.debug("Job #{runner_id} removed")
        rescue Kubeclient::ResourceNotFoundError
          Rails.logger.debug("Job #{runner_id} already removed")
        end

        Rails.logger.debug("Deleting pod")
        begin
          node.kubernetes_client.force_delete_pod(job_name: runner_id)
          Rails.logger.debug("Pod for job #{runner_id} removed")
        rescue Kubeclient::ResourceNotFoundError, KubernetesClient::PodNotFoundError
          Rails.logger.debug("Pod for job #{runner_id} already removed")
        end
      end
    end
  end
end
