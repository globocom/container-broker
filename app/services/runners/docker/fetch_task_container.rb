# frozen_string_literal: true

module Runners
  module Docker
    class FetchTaskContainer
      # TODO: This method returns a container object, it's specific to the the docker runner
      def perform(task:)
        ::Docker::Container.get(
          task.runner_id,
          { all: true },
          task.slot.node.docker_connection
        )
      end
    end
  end
end
