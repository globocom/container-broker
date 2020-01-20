# frozen_string_literal: true

module Runners
  module Docker
    class FetchLogs
      def perform(task:)
        Runners::ServicesFactory
          .fabricate(runner: task.slot.node.runner, service: :fetch_task_container)
          .perform(task: task)
          .streaming_logs(stdout: true, stderr: true, tail: 1_000)
      end
    end
  end
end
