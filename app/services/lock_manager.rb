class LockManager
  attr_reader :redis, :resource, :expire, :wait, :locked, :key
  KEY_PREFIX = "lockmanager-"

  def initialize(type:, id:, expire:, wait: true)
    @key = "#{KEY_PREFIX}-#{type}-#{id}"
    @redis = LockManager.redis_client
    @resource = resource
    @expire = expire
    @wait = wait
  end

  def lock
    if wait
      while !locked do
        sleep 0.1
        try_lock
      end
    else
      @locked = redis_set(nx: true)
    end

    if locked
      return yield(self)
    else
      false
    end
  ensure
    redis.del(key)
  end

  def keep_locked
    raise "Lock not aquired" unless locked

    if redis_set(xx: true)
      puts "[LockManager] lock extended by #{expire}"
    else
      raise "[LockManager] Lock expired"
    end
  end

  def self.active_locks
    redis_client.keys("#{KEY_PREFIX}*").inject(Hash.new) do |result, key|
      result[key] = redis_client.ttl(key)
      result
    end
  end

  def try_lock
    @locked = redis_set(nx: true)
  end

  def redis_set(options)
    redis.set(key, resource, options.merge(ex: expire))
  end

  def self.redis_client
    Redis.new(url: Settings.redis_url)
  end
end
