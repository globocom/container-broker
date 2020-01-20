# frozen_string_literal: true

module Runners
  module Docker
    class FetchExecutionInfo
      def perform(task:)
        info = ServicesFactory
               .fabricate(runner: :docker, service: :fetch_task_container)
               .perform(task: task)
               .info

        create_execution_info(info)
      end

      private

      def create_execution_info(info)
        state = info["State"]
        Runners::ExecutionInfo.new(
          id: info["id"],
          status: state["Status"],
          exit_code: state["ExitCode"],
          started_at: state["StartedAt"],
          finished_at: state["FinishedAt"],
          error: state["Error"]
        )
      end
    end
  end
end
