# frozen_string_literal: true

module Runners
  module Kubernetes
    class UpdateNodeStatus
      attr_reader :node

      def perform(node:)
        @node = node

        # Other tasks can be started at this time. Because of this it's necessary to load the tasks first and then the containers
        started_tasks = Task.started.where(:slot.in => node.slots.pluck(:id)).to_a

        node.update!(runner_capacity_reached: pending_schedule_pods?)

        execution_infos.each do |execution_info|
          runner_id = execution_info.id
          slot = node.slots.find_by(runner_id: runner_id)

          if slot
            if execution_info.terminated?
              Rails.logger.debug("Job #{runner_id} Complete")
              release_slot(slot: slot, runner_id: runner_id) if slot.running?
            else
              slot.current_task&.update!(error: execution_info.error) if execution_info.error
              Rails.logger.debug("Pod is not terminated (it is #{execution_info.status}). Ignoring.")
            end
          elsif Settings.ignore_containers.none? { |name| name.include?(runner_id) }
            Rails.logger.debug("Slot not found for job #{runner_id}. Removing job and pod.")
            RemoveContainerJob.perform_later(node: node, runner_id: runner_id)
          end
        end

        RescheduleTasksForMissingContainers
          .new(runner_ids: pods.keys, started_tasks: started_tasks)
          .perform

        node.update_last_success
      rescue SocketError, Kubeclient::HttpError => e
        node.register_error(e.message)
      end

      private

      def pods
        @pods ||= node.kubernetes_client.fetch_pods
      end

      def execution_infos
        @execution_infos ||= pods.values.map { |pod| CreateExecutionInfo.new.perform(pod: pod) }
      end

      def pending_schedule_pods?
        execution_infos.any?(&:schedule_pending?)
      end

      def release_slot(slot:, runner_id:)
        slot.releasing!
        ReleaseSlotJob.perform_later(slot: MongoidSerializableModel.new(slot), runner_id: runner_id)
      end
    end
  end
end
