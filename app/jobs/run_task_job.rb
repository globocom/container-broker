# frozen_string_literal: true

class RunTaskJob < ApplicationJob
  queue_as :default

  def perform(task:, slot:)
    Runners::ServicesFactory
      .fabricate(runner: slot.node.runner, service: :run_task)
      .perform(task: task, slot: slot)
  end
end
