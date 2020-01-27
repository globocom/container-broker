# frozen_string_literal: true

module Runners
  module Docker
    class FetchLogs
      def perform(task:)
        # streaming_logs avoids some encoding issues and should be safe since container status = exited
        # (see https://github.com/swipely/docker-api/issues/290 for reference)
        Runners::Docker::FetchTaskContainer
          .new
          .perform(task: task)
          .streaming_logs(stdout: true, stderr: true, tail: 1_000)
      end
    end
  end
end
