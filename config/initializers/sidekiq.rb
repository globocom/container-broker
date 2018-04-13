Rails.application.config.active_job.queue_adapter = :sidekiq

Sidekiq.configure_client do |config|
  config.redis = {url: "redis://localhost:6379/0/k9s" }
  # config.redis = {url: "redis://localhost:6379/0/k9s", concurrency: 1}
end

Sidekiq.default_worker_options = { retry: 0, backtrace: 10 }
