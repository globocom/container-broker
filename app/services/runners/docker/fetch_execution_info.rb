# frozen_string_literal: true

module Runners
  module Docker
    class FetchExecutionInfo
      def perform(task:)
        container = Runners::Docker::FetchTaskContainer
                    .new
                    .perform(task: task)

        CreateExecutionInfo.new.perform(container: container)
      end
    end
  end
end
