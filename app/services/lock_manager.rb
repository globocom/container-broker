class LockManager
  include Singleton
  attr_reader :manager

  def initialize
    @manager = Redlock::Client.new([ENV["DBAAS_REDIS_ENDPOINT"]])
  end

  def self.lock(resource, ttl, &block)
    instance.manager.lock(resource, ttl, &block)
  end
end
