# frozen_string_literal: true

module Runners
  module Kubernetes
    class FetchLogs
      def perform(task:)
        raise NotImplementedError, task
      end
    end
  end
end
