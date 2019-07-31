class UpdateNodeStatusJob < DockerConnectionJob
  queue_as :default

  def perform(node:)
    LockManager.new(type: "update-node-status", id: node.id, expire: 1.minute, wait: false).lock do
      update_node_status(node)
    end
  end

  private

  def update_node_status(node)
    @node = node

    containers = Docker::Container.all({all: true}, node.docker_connection)

    attached_slots = []

    containers.each do |container|
      slot = node.slots.where(container_id: container.id).first
      if slot
        attached_slots << slot
        if container.info["State"] == "exited"
          if slot.status == "running"
            slot.releasing!
            ReleaseSlotJob.perform_later(slot: MongoidSerializableModel.new(slot))
          end
        elsif started_with_error?(container: container, docker_connection: node.docker_connection)
          container.start
        end
      else
        container_names = container.info["Names"].map{|name| name.gsub(/\A\//, "") }

        if Settings.ignore_containers.none? { |name| container_names.any?{ |container_name| container_name.include?(name) } }
          # Here we remove lost containers, like those unknown to container-broker or by some cause
          # not linked here. But we need to take care to not remove those just created because
          # there is a sligthly time between their creation and its slot link that cannot be locked
          # so we remove only containers created at a minimum of 5 minutes
          if get_node_system_time(node: node) - Time.at(container.info["Created"]) > 5.minutes
            puts "Container #{container.id} not attached with any slot"
            Rails.logger.info("Container #{container.id} not attached with any slot")
            RemoveContainerJob.perform_later(node: node, container_id: container.id)
          end
        end
      end
    end

    node.update_last_success
  end

  def get_node_system_time(node:)
    @node_system_time ||= Time.parse(Docker.info(node.docker_connection)["SystemTime"])
  end

  def started_with_error?(container:, docker_connection:)
    container.info["State"] == "created" && Docker::Container.get(container.id, docker_connection).info["State"]["ExitCode"].positive?
  end
end
