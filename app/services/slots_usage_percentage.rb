class SlotsUsagePercentage
  def initialize(slots)
    @slots = slots
  end

  def perform
    (((@slots.size - idle_slots.size).to_f / @slots.size) * 100)
      .round(2)
  end

  private

  def idle_slots
    @slots.select(&:idle?)
  end
end
