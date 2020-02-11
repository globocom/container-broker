# frozen_string_literal: true

# It's important to persist migrated ids because there may be some tasks in the execution queue for the same runner id
class MigrateRunner
  TTL = Rails.env.development? ? 10.hours : 1.hour
  KEY_PREFIX = "migrated_ids"

  attr_reader :runner_id

  def initialize(runner_id:)
    @runner_id = runner_id
  end

  def migrate
    Rails.logger.info("Migrate runner id #{runner_id}")
    self.class.redis_client.set("#{KEY_PREFIX}_#{runner_id}", 1, ex: TTL)
  end

  def migrated?
    self.class.redis_client.exists("#{KEY_PREFIX}_#{runner_id}")
  end

  def self.redis_client
    redis_from_url(Settings.redis_url)
  end
end
