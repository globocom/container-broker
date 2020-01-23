# frozen_string_literal: true

module Runners
  module Docker
    class FetchExecutionInfo
      def perform(task:)
        container = ServicesFactory
                    .fabricate(runner: :docker, service: :fetch_task_container)
                    .perform(task: task)

        CreateExecutionInfo.new.perform(container: container)
      end
    end
  end
end
