# frozen_string_literal: true

class CurrentThreadRequestId
  ATTRIBUTE = "request_id"

  def self.get
    Thread.current[ATTRIBUTE]
  end

  def self.set(value)
    throw "Block is required" unless block_given?

    Thread.current[ATTRIBUTE] = value

    yield

    Thread.current[ATTRIBUTE] = nil
  end
end
