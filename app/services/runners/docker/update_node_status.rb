# frozen_string_literal: true

module Runners
  module Docker
    class UpdateNodeStatus
      def perform(node:)
        Rails.logger.debug("Start updating node status for #{node}")

        # Other tasks can be started at this time. Because of this it's necessary to load the tasks first and then the containers
        started_tasks = Task.started.where(:slot.in => node.slots.pluck(:id)).to_a

        containers = ::Docker::Container.all({ all: true }, node.docker_connection)

        Rails.logger.debug("Got #{containers.count} containers")

        containers.each do |container|
          container_names = container.info["Names"].map { |name| name.remove(%r{^/}) }

          slot = node.slots.find_by(:container_id.in => container_names)

          if slot
            container_name = slot.container_id

            Rails.logger.debug("Slot found for container #{container_name}: #{slot}")

            if container.info["State"] == "exited"
              Rails.logger.debug("Container #{container_name} exited")
              if slot.running?
                slot.releasing!
                Rails.logger.debug("Slot was running. Marked as releasing. Slot: #{slot}. Current task: #{slot.current_task}")
                ReleaseSlotJob.perform_later(slot: MongoidSerializableModel.new(slot), container_id: container.id)
              else
                Rails.logger.debug("Slot was not running (it was #{slot.status}). Ignoring.")
              end
            elsif started_with_error?(container: container, docker_connection: node.docker_connection)
              container.start
            end
          else
            Rails.logger.debug("Slot not found for container #{container_name}")

            if (Settings.ignore_containers & container_names).none?
              RemoveContainerJob.perform_later(node: node, container_id: container.id)
            else
              Rails.logger.debug("Container #{container_name} #{container_names} is ignored for removal")
            end
          end
        end

        RescheduleTasksForMissingContainers
          .new(containers: containers, started_tasks: started_tasks)
          .perform

        node.update_last_success
      rescue Excon::Error, ::Docker::Error::DockerError => e
        node.register_error(e.message)
      end

      private

      def started_with_error?(container:, docker_connection:)
        container.info["State"] == "created" && ::Docker::Container.get(container.id, docker_connection).info["State"]["ExitCode"].positive?
      end
    end
  end
end
