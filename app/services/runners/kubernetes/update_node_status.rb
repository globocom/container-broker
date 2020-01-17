# frozen_string_literal: true

module Runners
  module Kubernetes
    class UpdateNodeStatus
      attr_reader :node

      def initialize(node:)
        @node = node
      end

      def perform
        raise NotImplementedError
      end
    end
  end
end
