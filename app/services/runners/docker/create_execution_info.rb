# frozen_string_literal: true

module Runners
  module Docker
    class CreateExecutionInfo
      attr_reader :container

      def perform(container:)
        @container = container

        Runners::ExecutionInfo.new(
          id: container.info["id"],
          status: status,
          exit_code: state["ExitCode"],
          started_at: state["StartedAt"],
          finished_at: state["FinishedAt"],
          error: state["Error"]
        )
      end

      private

      def status
        if waiting?
          "pending"
        elsif running?
          "running"
        elsif terminated_with_success?
          "success"
        elsif terminated_with_error?
          "error"
        end
      end

      def waiting?
        state["Status"] == "created"
      end

      def running?
        state["Status"] == "running"
      end

      def terminated?
        state["Status"] == "exited"
      end

      def terminated_with_success?
        terminated? && state["ExitCode"]&.zero?
      end

      def terminated_with_error?
        terminated? && state["ExitCode"]&.positive?
      end

      def state
        container.info["State"]
      end
    end
  end
end
