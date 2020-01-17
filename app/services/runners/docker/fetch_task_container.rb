# frozen_string_literal: true

module Runners
  module Docker
    class FetchTaskContainer
      def perform(task:)
        ::Docker::Container.get(
          task.container_id,
          { all: true },
          task.slot.node.docker_connection
        )
      end
    end
  end
end
