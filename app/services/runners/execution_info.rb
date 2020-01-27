# frozen_string_literal: true

module Runners
  ExecutionInfo = Struct.new(:id, :status, :exit_code, :started_at, :finished_at, :error, :schedule_pending, keyword_init: true) do
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

    def schedule_pending?
      schedule_pending
    end
  end
end
