# frozen_string_literal: true

require "measures"

class Metrics
  attr_reader :client, :metric

  def initialize(metric)
    @metric = metric
    @transport = Measures::Transports::UDP.new(Settings.measures.host, Settings.measures.port)
    @client = Measures::Client.new(@transport, Settings.measures.index, Settings.measures.owner)
  end

  def count(data = {})
    client.count(metric, data) if enabled?
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
end
