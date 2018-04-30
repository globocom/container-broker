class HealthcheckController < ApplicationController
  def index
    render json: {
      status: "OK",
      sidekiq_redis: Sidekiq.redis_info["redis_version"],
      lock_manager_redis: LockManager.redis_client.info["redis_version"],
      mongodb: {
        nodes: Node.count,
        slots: Slot.count,
        pending_tasks: Task.where(status: "waiting").count
      }
    }
  rescue StandardError => e
    render json: {
      status: "ERROR",
      message: "#{e.class}: #{e.message}"
    }
  end
end
