# frozen_string_literal: true

module Runners
  module Docker
    class CreateConnection
      def perform(node:)
        raise(Runners::InvalidRunner, "Node must be a docker runner") unless node.docker?

        ::Docker::Connection.new(node.hostname, connect_timeout: 10, read_timeout: 10, write_timeout: 10)
      end
    end
  end
end
