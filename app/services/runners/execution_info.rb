# frozen_string_literal: true

module Runners
  class UnknownCompletionInformation < StandardError; end

  ExecutionInfo = Struct.new(:id, :status, :exit_code, :started_at, :finished_at, :error, :schedule_pending, keyword_init: true) do
    def success?
      check_completion_information_available

      status == "success"
    end

    def error?
      check_completion_information_available

      status == "error"
    end

    def running?
      status == "running"
    end

    def pending?
      status == "pending"
    end

    def terminated?
      exited_without_completion_information? || success? || error?
    end

    def exited_without_completion_information?
      status == "exited"
    end

    def schedule_pending?
      schedule_pending
    end

    private

    def check_completion_information_available
      # Some execution infos return just the "exited" status and not the complete state
      # So in this point, if the user is asking for success or error, then we need to force it
      # to fetch the complete status (which has the exit code)

      raise(UnknownCompletionInformation, "Complete status not available") if exited_without_completion_information?
    end
  end
end
