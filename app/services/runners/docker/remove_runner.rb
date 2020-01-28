# frozen_string_literal: true

module Runners
  module Docker
    class RemoveRunner
      def perform(node:, runner_id:)
        Rails.logger.info("Removing container #{runner_id} from node #{node}")
        container = ::Docker::Container.get(runner_id, { all: true }, node.docker_connection)
        container.kill if container.info["State"]["Status"] == "running"
        container.delete
      rescue ::Docker::Error::NotFoundError, ::Docker::Error::ConflictError => e
        Rails.logger.info("Container #{runner_id} already removed - #{e.message} (e.class)")
      rescue Excon::Error => e
        node.register_error(e.message)
      end
    end
  end
end
