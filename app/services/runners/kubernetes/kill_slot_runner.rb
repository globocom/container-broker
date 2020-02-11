# frozen_string_literal: true

module Runners
  module Kubernetes
    class KillSlotRunner
      def perform(slot:)
        RemoveRunner.new.perform(node: slot.node, runner_id: slot.runner_id)
      end
    end
  end
end
