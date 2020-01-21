# frozen_string_literal: true

module Runners
  module Docker
    class NodeAvailability
      def perform(node:)
        ::Docker.info(node.docker_connection)
      end
    end
  end
end
