# frozen_string_literal: true

module Runners
  module Kubernetes
    class FetchExecutionInfo
      def perform(task:)
        raise NotImplementedError, task
      end
    end
  end
end
