# frozen_string_literal: true

class CollectLoadMetrics
  def perform
    send_tasks_count
    send_slots_count
    send_slots_usage_percent
  end

  private

  def send_tasks_count
    send_metrics("tasks_count", Task.where(:status.in => %w[waiting starting started retry failed]))
  end

  def send_slots_count
    send_metrics("slots_count", Node.available.flat_map(&:slots))
  end

  def send_slots_usage_percent
    Node
      .available
      .flat_map(&:slots)
      .group_by(&:execution_type)
      .each do |execution_type, slots|
        Metrics.new("slots_usage_percent").count(execution_type: execution_type, percent: SlotsUsagePercentage.new(slots).perform)
      end
  end

  def send_metrics(metric, items)
    items
      .group_by { |s| { execution_type: s.execution_type, status: s.status } }
      .transform_values(&:count)
      .each do |data, count|
        Metrics.new(metric).count(
          data.merge(amount: count)
        )
      end
  end
end
