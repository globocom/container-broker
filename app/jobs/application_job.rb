# frozen_string_literal: true

class ApplicationJob < ActiveJob::Base
  JOB_METRIC = "jobs"

  around_perform do |job, block|
    time = Benchmark.realtime { block.call }

    Metrics.new(JOB_METRIC).count(
      job_id: job.job_id,
      job_class: job.class.to_s,
      executions: job.executions,
      queue_name: job.queue_name,
      hostname: Socket.gethostname,
      time: time
    )
  end
end
