# frozen_string_literal: true

module Runners
  module Docker
    class CreateConnection
      def perform(node:)
        raise(Runners::InvalidRunner, "Node must be a docker runner") unless node.docker?

        ::Docker::Connection.new(
          node.hostname,
          connect_timeout: 5,
          read_timeout: 5,
          write_timeout: 5
        )
      end
    end
  end
end
