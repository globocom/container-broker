class UpdateNodeStatusJob < DockerConnectionJob
  queue_as :default

  def perform(node:)
    @node = node

    LockManager.new(type: "monitor_node", id: node.id, expire: 1.minute, wait: false).lock do |lock_manager|
      containers = Docker::Container.all({all: true}, node.docker_connection)

      attached_slots = []

      containers.each do |container|
        lock_manager.keep_locked

        slot = node.slots.where(container_id: container.id).first
        if slot
          attached_slots << slot
          if container.info["State"] == "exited"
            if slot.status == "running"
                # slot.reload
                # if slot.status == "running" # if slot status STILLS running after locking
                  slot.update(status: "releasing")
                  ReleaseSlotJob.perform_later(slot: MongoidSerializableModel.new(slot))
                # end
              # end
            end
          else
            # UpdateTaskStatusJob.perform_later(Task.find(slot.current_task.id))
          end
        else
          puts "Container #{container.id} not attached with any slot"
          Rails.logger.info("Container #{container.id} not attached with any slot")
          RemoveContainerJob.perform_later(node: node, container_id: container.id)
        end
      end

      zombie_slots = node.slots.where(status: "running") - attached_slots
      zombie_slots.each do |slot|
        ReleaseSlotJob.perform_later(slot: MongoidSerializableModel.new(slot))
      end

      RunTasksJob.perform_later
    end
  end
end
