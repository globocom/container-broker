# frozen_string_literal: true

module Runners
  module Docker
    class CreateExecutionInfo
      attr_reader :container

      def perform(container:)
        @container = container

        exeuction_info_data = {
          id: container.info["Names"].first.remove(%r{^/}),
          status: status
        }

        if full_state_present?
          exeuction_info_data.merge!(
            exit_code: state["ExitCode"],
            started_at: state["StartedAt"],
            finished_at: state["FinishedAt"],
            error: state["Error"]
          )
        end

        Runners::ExecutionInfo.new(exeuction_info_data)
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
        elsif terminated?
          "exited"
        end
      end

      def waiting?
        state_status == "created"
      end

      def running?
        state_status == "running"
      end

      def terminated?
        state_status == "exited"
      end

      def terminated_with_success?
        terminated? && state["ExitCode"]&.zero?
      end

      def terminated_with_error?
        terminated? && state["ExitCode"]&.positive?
      end

      def full_state_present?
        state.is_a?(Hash)
      end

      def state
        container.info["State"]
      end

      def state_status
        if full_state_present?
          state["Status"]
        else
          state
        end
      end
    end
  end
end
