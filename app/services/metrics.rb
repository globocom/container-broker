require "measures"

class Metrics
  attr_reader :client

  def initialize
    @transport = Measures::Transports::UDP.new(Settings.measures.host, Settings.measures.port)
    @client = Measures::Client.new(@transport, Settings.measures.index, Settings.measures.owner)
  end

  def count(metric, data={})
    client.count(metric, data) if enabled?
  end

  def time(metric, data={}, &block)
    if enabled?
      client.time(metric, data) { yield if block_given? }
    else
      yield if block_given?
    end
  end

  private

  def enabled?
    Settings.measures.enabled
  end
end
