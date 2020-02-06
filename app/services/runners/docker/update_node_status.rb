# frozen_string_literal: true

module Runners
  module Docker
    class UpdateNodeStatus
      include UpdateNodeStatusHelper

      attr_reader :node

      def perform(node:)
        @node = node
        Rails.logger.debug("Start updating node status for #{node}")

        # Other tasks can be started at this time. Because of this it's necessary to load the tasks first and then the containers
        started_tasks = Task.started.where(:slot.in => node.slots.pluck(:id)).to_a

        Rails.logger.debug("Got #{containers.count} containers")

        execution_infos = containers.map do |container|
          execution_info = CreateExecutionInfo.new.perform(container: container)

          slot = node.slots.find_by(runner_id: execution_info.id)
          if slot
            Rails.logger.debug("Slot found for container #{execution_info.id}: #{slot}")

            if execution_info.terminated?
              Rails.logger.debug("Container #{execution_info.id} exited")

              check_slot_release(slot: slot, runner_id: execution_info.id)
            elsif started_with_error?(container: container, docker_connection: node.docker_connection)
              container.start
            end
          else
            remove_unknown_runner(node: node, runner_id: execution_info.id)
          end

          execution_info
        end

        RescheduleTasksForMissingRunners
          .new(runner_ids: execution_infos.map(&:id), started_tasks: started_tasks)
          .perform

        node.register_success

        send_metrics(node: node, execution_infos: execution_infos)
      rescue Excon::Error, ::Docker::Error::DockerError => e
        node.register_error(e.message)
      end

      private

      def containers
        @containers ||= ::Docker::Container.all({ all: true }, node.docker_connection)
      end

      def started_with_error?(container:, docker_connection:)
        container.info["State"] == "created" && ::Docker::Container.get(container.id, docker_connection).info["State"]["ExitCode"].positive?
      end
    end
  end
end
