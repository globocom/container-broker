# frozen_string_literal: true

module Runners
  module Kubernetes
    class UpdateNodeStatus
      def perform(node:)
        raise NotImplementedError, node
      end
    end
  end
end
