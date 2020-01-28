# frozen_string_literal: true

class KillNodeRunners
  attr_reader :node

  def initialize(node:)
    @node = node
  end

  def perform
    node.slots.running.each do |slot|
      node
        .runner_service(:kill_slot_runner)
        .perform(slot: slot)
    end
  end
end
