# frozen_string_literal: true

module Runners
  module Kubernetes
    class UpdateNodeStatus
      include UpdateNodeStatusHelper

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
              check_slot_release(slot: slot, runner_id: runner_id)
            else
              slot.current_task&.update!(error: execution_info.error) if execution_info.error
              Rails.logger.debug("Pod is not terminated (it is #{execution_info.status}). Ignoring.")
            end
          else
            remove_unknown_runners(node: node, runner_ids: [runner_id])
          end
        end

        RescheduleTasksForMissingRunners
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
    end
  end
end
