# frozen_string_literal: true

module Runners
  module Docker
    class FetchExecutionInfo
      def perform(task:)
        container = Runners::Docker::FetchTaskContainer
                    .new
                    .perform(task: task)

        CreateExecutionInfo.new.perform(container: container)
      rescue Docker::Error::NotFoundError => e
        raise Runners::RunnerIdNotFoundError, e.message
      end
    end
  end
end
