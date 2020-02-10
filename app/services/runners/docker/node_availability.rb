# frozen_string_literal: true

module Runners
  module Docker
    class NodeAvailability
      def perform(node:)
        ::Docker.info(CreateConnection.new.perform(node: node))
      end
    end
  end
end
