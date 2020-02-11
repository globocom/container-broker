# frozen_string_literal: true

module Runners
  module Docker
    class FetchTaskContainer
      def perform(task:)
        ::Docker::Container.get(
          task.runner_id,
          { all: true },
          CreateConnection.new.perform(node: task.slot.node)
        )
      end
    end
  end
end
