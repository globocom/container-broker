class ApplicationJob < ActiveJob::Base
  JOB_METRIC = "jobs"

  around_perform do |job, block|
    Metrics.new(JOB_METRIC).duration do |metric|
      metric[:job_id] = job.job_id
      metric[:job_class] = job.class.to_s
      metric[:executions] = job.executions
      metric[:queue_name] = job.queue_name
      metric[:hostname] = `hostname`&.strip

      block.call
    end
  end
end
