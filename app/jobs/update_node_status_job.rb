# frozen_string_literal: true

class UpdateNodeStatusJob < ApplicationJob
  queue_as :default

  def perform(node:)
    Rails.logger.debug("Waiting for lock to update status of #{node}")

    updated = LockManager.new(type: self.class.to_s, id: node.id, expire: 1.minute, wait: false).lock do
      Rails.logger.debug("Lock acquired for update status of #{node}")
      update_node_status(node)
      Rails.logger.debug("Releasing lock for update status of #{node}")
      true
    end

    if updated
      Rails.logger.debug("Lock released for update status of #{node}")
    else
      Rails.logger.debug("Node updating is locked by another job and will be ignored now")
    end
  end

  private

  def update_node_status(node)
    Rails.logger.debug("Start updating node status for #{node}")

    # Other tasks can be started at this time. Because of this it's necessary to load the tasks first and then the containers
    started_tasks = Task.started.where(:slot.in => node.slots.pluck(:id)).to_a
    containers = Docker::Container.all({ all: true }, node.docker_connection)

    Rails.logger.debug("Got #{containers.count} containers")

    containers.each do |container|
      slot = node.slots.where(container_id: container.id).first
      if slot
        Rails.logger.debug("Slot found for container #{container.id}: #{slot}")

        if container.info["State"] == "exited"
          Rails.logger.debug("Container #{container.id} exited")
          if slot.status == "running"
            slot.releasing!
            Rails.logger.debug("Slot was running. Marked as releasing. slot: #{slot} current_task: #{slot.current_task}")
            ReleaseSlotJob.perform_later(slot: MongoidSerializableModel.new(slot), container_id: container.id)
          else
            Rails.logger.debug("Slot was not running (it was #{slot.status}). Ignoring.")
          end
        elsif started_with_error?(container: container, docker_connection: node.docker_connection)
          container.start
        end
      else
        Rails.logger.debug("Slot not found for container #{container.id}")

        container_names = container.info["Names"].map { |name| name.gsub(%r{\A/}, "") }

        if Settings.ignore_containers.none? { |name| container_names.any? { |container_name| container_name.include?(name) } }
          remove_container_if_expired(node: node, container: container, container_names: container_names)
        else
          Rails.logger.debug("Container #{container.id} #{container_names} is ignored for removal")
        end
      end
    end

    RescheduleTasksForMissingContainers
      .new(containers: containers, started_tasks: started_tasks)
      .perform

    node.update_last_success
  rescue Excon::Error, Docker::Error::DockerError => e
    node.register_error(e.message)
  end

  def get_node_system_time(node:)
    @node_system_time ||= Time.parse(Docker.info(node.docker_connection)["SystemTime"])
  end

  def started_with_error?(container:, docker_connection:)
    container.info["State"] == "created" && Docker::Container.get(container.id, docker_connection).info["State"]["ExitCode"].positive?
  end

  def remove_container_if_expired(node:, container:, container_names:)
    Rails.logger.debug("Container #{container.id} #{container_names} is not ignored for removal")

    # Here we remove lost containers, like those unknown to container-broker or by some cause
    # not linked here. But we need to take care to not remove those just created because
    # there is a sligthly time between their creation and its slot link that cannot be locked
    # so we remove only containers created at a minimum of 5 minutes
    return if get_node_system_time(node: node) - Time.at(container.info["Created"]) < 5.minutes

    Rails.logger.debug("Container #{container.id} created before 5 minutes ago and is enqueued to be removed")
    Rails.logger.info("Container #{container.id} not attached with any slot")

    RemoveContainerJob.perform_later(node: node, container_id: container.id)
  end
end
