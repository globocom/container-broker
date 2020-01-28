# frozen_string_literal: true

module Runners
  module Docker
    class KillSlotRunner
      def perform(slot:)
        return unless slot.runner_id.present?

        ::Docker::Container
          .get(slot.runner_id, {}, slot.node.docker_connection)
          .kill!
      rescue ::Docker::Error::NotFoundError => e
        Rails.logger.info("Container #{slot.runner_id} already removed - #{e.message} (e.class)")
      rescue Excon::Error => e
        Rails.logger.info("Error removing container: #{e}")
      end
    end
  end
end
