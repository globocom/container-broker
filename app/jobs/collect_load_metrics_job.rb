# frozen_string_literal: true

class CollectLoadMetricsJob < ContainerBrokerBaseJob
  queue_as :default

  def perform
    CollectLoadMetrics.new.perform
  end
end
