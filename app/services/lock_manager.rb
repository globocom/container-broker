# frozen_string_literal: true

class LockManager
  attr_reader :expire, :wait, :locked, :key

  KEY_PREFIX = "lockmanager"

  def initialize(type:, id:, expire:, wait: true)
    @key = "#{KEY_PREFIX}-#{type}-#{id}"
    @expire = expire
    @wait = wait
  end

  def lock
    if lock!
      begin
        yield(self) if block_given?
      ensure
        unlock!
      end
    else
      false
    end
  end

  def lock!
    try_lock

    if wait
      until locked
        sleep 0.1
        try_lock
      end
    end

    locked
  end

  def unlock!
    redis_client.del(key)
    @locked = false
  end

  def keep_locked
    raise "Lock not acquired" unless locked

    if redis_set(xx: true)
      puts "[LockManager] lock extended by #{expire}"
    else
      raise "[LockManager] Lock expired"
    end
  end

  def self.active_locks
    redis_client.keys("#{KEY_PREFIX}*").each_with_object({}) do |key, result|
      result[key] = redis_client.ttl(key)
    end
  end

  def try_lock
    @locked = redis_set(nx: true)
  end

  def redis_set(options)
    redis_client.set(key, 1, **options.merge(ex: expire))
  end

  def redis_client
    LockManager.redis_client
  end

  def self.redis_client
    Redis.new(RedisUrlParser.call(Settings.redis_url))
  end
end
