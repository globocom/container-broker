# frozen_string_literal: true

module Runners
  class ExecutionInfo < Struct.new(:id, :status, :exit_code, :started_at, :finished_at, :error, keyword_init: true)
    def success?
      status == "success"
    end

    def error?
      status == "error"
    end

    def running?
      status == "running"
    end

    def pending?
      status == "pending"
    end

    def terminated?
      success? || error?
    end
  end
end
