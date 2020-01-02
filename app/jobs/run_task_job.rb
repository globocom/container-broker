# frozen_string_literal: true

class RunTaskJob < ApplicationJob
  queue_as :default

  def perform(task:, slot:)
    Rails.logger.debug("Performing RunTaskJob for #{task} #{slot}")

    pull_image(task: task, slot: slot)
    Rails.logger.debug("Image pulled for #{task} #{slot}")

    container = create_container(task: task, slot: slot)
    Rails.logger.debug("Container #{container.id} created for #{task} #{slot}")

    task.update!(container_id: container.id, slot: slot)
    Rails.logger.debug("#{task} updated with #{container.id} #{slot}")

    container.start
    Rails.logger.debug("Container #{container.id} started")

    task.mark_as_started!
    Rails.logger.debug("#{task} marked as started")

    slot.mark_as_running(current_task: task, container_id: container.id)
    Rails.logger.debug("#{slot} marked as running")

    add_metric(task)
    task
  rescue StandardError, Excon::Error => e
    Rails.logger.debug("Error in RunTaskJob: #{e}")
    case e
    when Excon::Error, Docker::Error::TimeoutError then
      message = "Docker connection error: #{e.message}"
      message += "\n#{e.response.body}" if e.respond_to?(:response)
      slot.node.register_error(message)
    when Docker::Error::NotFoundError
      message = "Docker image not found: #{e.message}"
    else
      message = e.message
    end

    slot.release
    Rails.logger.debug("#{slot} released")

    task.update!(error: message)
    Rails.logger.debug("#{task} error updated with '#{message}'")

    add_metric(task)

    task.mark_as_retry
    Rails.logger.debug("#{task} marked as retry")
  end

  def add_metric(task)
    Metrics.new("tasks").count(
      task_id: task.id,
      name: task&.name,
      type: task&.execution_type,
      slot: task&.slot&.name,
      node: task&.slot&.node&.name,
      started_at: task.started_at,
      duration: task.milliseconds_waiting,
      error: task.error,
      status: task.status
    )
  end

  def pull_image(task:, slot:)
    unless Docker::Image.exist?(task.image, {}, slot.node.docker_connection)
      image_name, image_tag = task.image.split(":")
      Docker::Image.create({ "fromImage" => image_name, "tag" => image_tag }, nil, slot.node.docker_connection)
    end
  end

  def create_container(task:, slot:)
    binds = []
    binds << Filer::Container.bind(task.storage_mount) if task.storage_mount.present?
    binds << Filer::Ingest.bind(task.ingest_storage_mount) if task.ingest_storage_mount.present?

    Docker::Container.create(
      {
        "Image" => task.image,
        "HostConfig" => {
          "Binds" => binds,
          "NetworkMode" => ENV["DOCKER_CONTAINERS_NETWORK"].to_s
        },
        "Entrypoint" => [],
        "Cmd" => ["sh", "-c", task.cmd]
      },
      slot.node.docker_connection
    )
  end
end
