# frozen_string_literal: true

class ContainerBrokerBaseJob < ApplicationJob
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

  around_perform do |job, block|
    request_id = job.class.request_id_from_args(job.arguments.first)

    if request_id
      Rails.logger.tagged(" request_id=#{request_id} ") do
        CurrentThreadRequestId.set(request_id) { block.call }
      end
    else
      block.call
    end
  end

  def self.request_id_from_args(_args); end
end
