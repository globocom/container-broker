# frozen_string_literal: true

module Runners
  module Kubernetes
    class NodeAvailability
      def perform(node:)
        CreateClient.new.perform(node: node).api_info
      end
    end
  end
end
