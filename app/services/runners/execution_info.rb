# frozen_string_literal: true

module Runners
  class ExecutionInfo
    attr_accessor :id, :status, :exit_code, :started_at, :finished_at, :error

    def initialize(values = {})
      values.each { |key, value| send("#{key}=", value) }
    end
  end
end
