# frozen_string_literal: true

Rails.application.config.middleware.use(
  IdempotentRequest::Middleware,
  storage: IdempotentRequest::RedisStorage.new(
    Redis.new(RedisUrlParser.call(Settings.redis_url)),
    expire_time: 1.day
  ),
  header_key: "X-Idempotency-Key",
  policy: IdempotentRequest::Policy,
  callback: IdempotentRequest::Callback
)
