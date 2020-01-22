# frozen_string_literal: true

module Runners
  module Kubernetes
    class FetchExecutionInfo
      attr_reader :task

      def perform(task:)
        @task = task

        create_execution_info
      end

      private

      def create_execution_info
        Runners::ExecutionInfo.new(
          id: task.container_id,
          status: status,
          exit_code: container_status&.state&.terminated&.exitCode,
          started_at: started_at,
          finished_at: container_status&.state&.terminated&.finishedAt,
          error: error_message
        )
      end

      def status
        if terminated?
          "exited"
        elsif started?
          "started"
        end
      end

      def terminated?
        container_status&.state&.terminated.present?
      end

      def running?
        container_status&.state&.running&.present?
      end

      def started?
        terminated? || running?
      end

      def success?
        container_status&.state&.terminated&.exitCode&.zero?
      end

      def error_message
        return if success?

        container_status&.state&.terminated&.reason
      end

      def started_at
        (container_status&.state&.terminated || container_status&.state&.running)&.startedAt
      end

      def container_status
        pod.status&.containerStatuses&.first
      end

      def pod
        @pod ||= kubernetes_client.fetch_pod(job_name: task.container_id)
      end

      def kubernetes_client
        @kubernetes_client ||= task.slot.node.kubernetes_client
      end
    end
  end
end
