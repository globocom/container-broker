# frozen_string_literal: true

class CurrentThreadRequestId
  ATTRIBUTE = "request_id"

  def self.get
    Thread.current[ATTRIBUTE]
  end

  def self.set(value)
    throw "no block given" unless block_given?

    Thread.current[ATTRIBUTE] = value

    yield
  ensure
    Thread.current[ATTRIBUTE] = nil
  end
end
