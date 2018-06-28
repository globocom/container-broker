class RunTaskJob < ApplicationJob
  queue_as :default

  def perform(task:, slot:)
    @node = slot.node

    pull_image(task: task, slot: slot)

    container = create_container(task: task, slot: slot)
    container.start

    task.mark_as_started(container_id: container.id, slot: slot)
    slot.mark_as_running(current_task: task, container_id: container.id)

    task
  rescue StandardError, Excon::Error => e
    Rails.logger.error("Error in RunTaskJob: #{e}")
    case e
    when Excon::Error, Docker::Error::TimeoutError then
      message = "Docker connection error: #{e.message}"
      message << "\n#{e.response.body}" if e.respond_to?(:response)
      slot.node.unavailable!(error: message)
    when Docker::Error::NotFoundError then
      message = "Docker image not found: #{e.message}"
    end

    slot.release
    task.update(error: message, slot: nil, container_id: nil)
    task.retry
  end

  def pull_image(task:, slot:)
    unless Docker::Image.exist?(task.image, {}, slot.node.docker_connection)
      image_name, image_tag = task.image.split(":")
      Docker::Image.create({"fromImage" => image_name, "tag" => image_tag}, nil, slot.node.docker_connection)
    end
  end

  def create_container(task:, slot:)
    binds = []
    binds << [Settings.filer_dir_base, task.storage_mount].join(":") if task.storage_mount.present?

    Docker::Container.create(
      {
        "Image" => task.image,
        "HostConfig" => {
          "Binds" => binds,
          "LogConfig" => log_config,
          "NetworkMode" => ENV["DOCKER_CONTAINERS_NETWORK"].to_s
        },
        "Cmd" => task.cmd.split(/\s(?=(?:[^']|'[^']*')*$)/)
      },
      slot.node.docker_connection
    )
  end

  def log_config
    case Settings.docker_log_driver
    when "fluentd" then
      {
        "Type" => "fluentd",
        "Config" => {
          "tag" => "docker.{{.ID}}",
          "fluentd-sub-second-precision" => "true"
        }
      }
    else
      {
        "Type" => "json-file"
      }
    end
  end
end
