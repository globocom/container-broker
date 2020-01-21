# frozen_string_literal: true

module Runners
  module Kubernetes
    class UpdateNodeStatus
      def perform(node:)
        node.kubernetes_client.fetch_jobs_status.each do |job_name, resource|
          slot = node.slots.find_by(container_id: job_name)

          unless slot
            Rails.logger.debug("Slot not found for job #{job_name}")
            next
          end

          running = resource.succeeded.to_i.zero? && resource.failed.to_i.zero?
          next if running

          Rails.logger.debug("Job #{job_name} Complete")
          if slot.running?
            slot.releasing!
            ReleaseSlotJob.perform_later(slot: MongoidSerializableModel.new(slot), container_id: job_name)
          else
            Rails.logger.debug("Slot was not running (it was #{slot.status}). Ignoring.")
          end
        end

        node.update_last_success
      rescue SocketError, Kubeclient::HttpError => e
        node.register_error(e.message)
      end
    end
  end
end
