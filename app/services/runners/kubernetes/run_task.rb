# frozen_string_literal: true

module Runners
  module Kubernetes
    class RunTask
      def perform(task:, slot:)
        raise NotImplementedError, task, slot
      end
    end
  end
end
