class LockManager
  include Singleton
  attr_reader :manager

  def initialize
    @manager = Redlock::Client.new([Settings.sidekiq_url])
  end

  def self.lock(resource, ttl, &block)
    instance.manager.lock(resource, ttl, &block)
  end

end
