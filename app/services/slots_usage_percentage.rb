# frozen_string_literal: true

class SlotsUsagePercentage
  def initialize(slots)
    @slots = slots
  end

  def perform
    (((@slots.size - available_slots.size).to_f / @slots.size) * 100)
      .round(2)
  end

  private

  def available_slots
    @slots.select(&:available?)
  end
end
