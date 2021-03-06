# frozen_string_literal: true

require "measures"

class Metrics
  attr_reader :metric

  def initialize(metric)
    @metric = metric
  end

  def count(data = {})
    return unless enabled?

    client.count(metric, data.merge(
                           origin: "container-broker"
                         ))
  rescue StandardError => e
    Rails.logger.warn("Error sending metrics to measures: #{e}")
  end

  def duration(data = {})
    if enabled?
      client.time(metric, data) { yield data if block_given? }
    else
      yield data if block_given?
    end
  end

  private

  def enabled?
    Settings.measures.enabled
  end

  def transport
    Measures::Transports::UDP.new(Settings.measures.host, Settings.measures.port)
  end

  def client
    Measures::Client.new(transport, Settings.measures.index, Settings.measures.owner)
  end
end
