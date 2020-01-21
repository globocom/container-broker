# frozen_string_literal: true

module Runners
  module Kubernetes
    class NodeAvailability
      def perform(node:)
        node.kubernetes_client.api_info
      end
    end
  end
end
