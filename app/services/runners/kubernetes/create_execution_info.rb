# frozen_string_literal: true

module Runners
  module Kubernetes
    class CreateExecutionInfo
      attr_reader :pod

      ERROR_REASONS = %w[
        ImagePullBackOff
        ErrImagePull
      ].freeze

      def perform(pod:)
        @pod = pod

        Runners::ExecutionInfo.new(
          id: pod&.metadata&.labels&.dig(:"job-name"),
          status: status,
          exit_code: container_status&.state&.terminated&.exitCode,
          started_at: started_at,
          finished_at: container_status&.state&.terminated&.finishedAt,
          error: error_message
        )
      end

      private

      def status
        if running?
          "running"
        elsif terminated_with_success?
          "success"
        elsif error?
          "error"
        elsif waiting?
          "pending"
        end
      end

      def waiting?
        container_status&.state&.waiting.present?
      end

      def running?
        container_status&.state&.running&.present?
      end

      def terminated_with_error?
        container_status&.state&.terminated&.exitCode&.positive?
      end

      def terminated_with_success?
        container_status&.state&.terminated&.exitCode&.zero?
      end

      def reason_is_error?
        waiting? && ERROR_REASONS.include?(reason[:reason])
      end

      def error?
        terminated_with_error? || reason_is_error? || schedulable_error_messsage
      end

      def schedulable_error_messsage
        return if pod.status&.phase != "Pending"

        found = pod&.status&.conditions&.find { |condition| condition.reason == "Unschedulable" }
        "#{found.reason}: #{found.message}" if found
      end

      def error_message
        return unless error?

        return schedulable_error_messsage if schedulable_error_messsage.present?

        reason.values.compact.join(": ")
      end

      def started_at
        (container_status&.state&.terminated || container_status&.state&.running)&.startedAt
      end

      def reason
        reason_value = container_status&.state&.to_hash&.values&.first
        return {} unless reason_value

        {
          reason: reason_value[:reason],
          message: reason_value[:message]
        }
      end

      def container_status
        pod.status&.containerStatuses&.first
      end
    end
  end
end
