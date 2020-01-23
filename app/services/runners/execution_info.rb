# frozen_string_literal: true

module Runners
  ExecutionInfo = Struct.new(:id, :status, :exit_code, :started_at, :finished_at, :error, keyword_init: true)
end
