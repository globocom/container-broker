# frozen_string_literal: true

module Runners
  module Kubernetes
    class UpdateNodeStatus
      def perform(node:)
        puts "=> UpdateNodeStatus on #{node}"
      end
    end
  end
end
