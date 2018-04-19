class LockManager
  attr_reader :redis, :resource, :expire, :wait, :locked, :key

  def initialize(type:, id:, expire:, wait: true)
    @key = "lockmanager-#{type}-#{id}"
    @redis = Redis.new(url: Settings.redis_url)
    @resource = resource
    @expire = expire
    @wait = wait
  end

  def lock
    if wait
      while !locked do
        sleep 0.1
        @locked = redis_set(nx: true)
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
      puts "lock extended by #{expire}"
    else
      raise "Lock expired"
    end
  end

  def redis_set(options)
    redis.set(key, resource, options.merge(ex: expire))
  end
end
