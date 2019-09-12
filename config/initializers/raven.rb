# frozen_string_literal: true

if Settings.sentry.enabled
  require "raven"

  Raven.configure do |config|
    config.dsn = "https://#{Settings.sentry.app.public_key}:#{Settings.sentry.app.private_key}@#{Settings.sentry.host}/#{Settings.sentry.app.project_id}"
    config.ssl_verification = false
  end
end
