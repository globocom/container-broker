# frozen_string_literal: true

class RemoveRunnerJob < ApplicationJob
  queue_as :default

  def perform(node:, runner_id:)
    node
      .runner_service(:remove_runner)
      .perform(node: node, runner_id: runner_id)
  end
end
