Rails.application.config.active_job.queue_adapter = Rails.env.test? ? :test : :sidekiq

Sidekiq.default_worker_options = { backtrace: true }

def redis_from_url(uri)
  if uri.start_with?("sentinel")
    m = uri.match("sentinel://:([^@]*)@([^/]*)/service_name:(.*)")
    password = m[1]
    sentinel_uris = m[2]
    name = m[3]
    url = "redis://:#{password}@#{name}"
    sentinels = sentinel_uris.split(",").map do |sentinel_uri|
      host, port = sentinel_uri.split(":")
      {
        host: host,
        port: port,
      }
    end
    Redis.new(url: url, sentinels: sentinels)
  else
    Redis.new(url: uri)
  end
end

connection = proc {
  redis_from_url(Settings.redis_url)
}

Sidekiq.configure_server do |config|
  config.redis = ConnectionPool.new(size: 50, &connection)
end

Sidekiq.configure_client do |config|
  config.redis = ConnectionPool.new(size: 50, &connection)
end
