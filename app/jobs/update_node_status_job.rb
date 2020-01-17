# frozen_string_literal: true

class UpdateNodeStatusJob < ApplicationJob
  queue_as :default

  def perform(node:)
    Rails.logger.debug("Waiting for lock to update status of #{node}")

    updated = LockManager.new(type: self.class.to_s, id: node.id, expire: 1.minute, wait: false).lock do
      Rails.logger.debug("Lock acquired for update status of #{node}")

      Runners::Fabricate.update_node_status(node: node).perform

      Rails.logger.debug("Releasing lock for update status of #{node}")
      true
    end

    if updated
      Rails.logger.debug("Lock released for update status of #{node}")
    else
      Rails.logger.debug("Node updating is locked by another job and will be ignored now")
    end
  end
end
