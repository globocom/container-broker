# frozen_string_literal: true

module Runners
  module Kubernetes
    class UpdateNodeStatus
      def perform(node:)
        node.kubernetes_client.fetch_pods.each do |job_name, pod|
          slot = node.slots.find_by(container_id: job_name)
          if slot
            execution_info = CreateExecutionInfo.new.perform(pod: pod)
            unless execution_info.terminated?
              Rails.logger.debug("Pod is not terminated (it is #{execution_info.status}). Ignoring.")
              next
            end

            Rails.logger.debug("Job #{job_name} Complete")
            if slot.running?
              slot.releasing!
              ReleaseSlotJob.perform_later(slot: MongoidSerializableModel.new(slot), container_id: job_name)
            end
          else
            Rails.logger.debug("Slot not found for job #{job_name}. Removing job and pod.")
            RemoveContainerJob.perform_later(node: node, container_id: job_name)
          end
        end

        node.update_last_success
      rescue SocketError, Kubeclient::HttpError => e
        node.register_error(e.message)
      end
    end
  end
end
