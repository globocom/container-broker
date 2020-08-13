# frozen_string_literal: true

Rails.application.config.active_job.queue_adapter = Rails.env.test? ? :test : :sidekiq

Sidekiq.default_worker_options = { backtrace: true }

connection = proc {
  Redis.new(RedisUrlParser.call(Settings.redis_url))
}

Sidekiq.configure_server do |config|
  config.redis = ConnectionPool.new(size: 50, &connection)
  config.logger.level = Logger::DEBUG

  config.on(:startup) do
    Sidekiq.schedule = YAML.load_file(File.expand_path("../sidekiq_scheduler.yml", __dir__))
    SidekiqScheduler::Scheduler.instance.reload_schedule!
  end
end

Sidekiq.configure_client do |config|
  config.redis = ConnectionPool.new(size: 50, &connection)
  config.logger.level = Logger::DEBUG
end
