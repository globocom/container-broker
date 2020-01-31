# frozen_string_literal: true

module Runners
  class UnknownCompletionStatus < StandardError; end

  ExecutionInfo = Struct.new(:id, :status, :exit_code, :started_at, :finished_at, :error, :schedule_pending, keyword_init: true) do
    def success?
      check_full_state_available

      status == "success"
    end

    def error?
      check_full_state_available

      status == "error"
    end

    def running?
      status == "running"
    end

    def pending?
      status == "pending"
    end

    def terminated?
      exited? || success? || error?
    end

    def exited?
      status == "exited"
    end

    def schedule_pending?
      schedule_pending
    end

    private

    def check_full_state_available
      # Some execution infos return just the "exited" status and not the complete state
      # So in this point, if the user is asking for success or error, then we need to force it
      # to fetch the complete status (which has the exit code)

      raise(UnknownCompletionStatus, "Complete status not available") if exited?
    end
  end
end
