# frozen_string_literal: true

module Runners
  module Kubernetes
    class NodeAvailability
      def perform(node:)
        puts "---> NodeAvailability on #{node}"
        # Calls method cluster_info in kubernetes client
      end
    end
  end
end
