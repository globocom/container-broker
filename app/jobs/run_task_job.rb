class RunTaskJob < ApplicationJob
  queue_as :default

  def perform(task:, slot:)
    @node = slot.node

    image_name, image_tag = task.image.split(':')
    Docker::Image.create({'fromImage' => image_name, 'tag' => image_tag}, nil, slot.node.docker_connection)
    container = Docker::Container.create(
      {
        'Image' => task.image,
        'HostConfig' => {
          'Binds' => ['/root/ef-shared:/tmp/workdir'],
          'LogConfig' =>  {
            'Type' => 'fluentd',
            'Config' => {
              "tag" => "docker.{{.ID}}"
            }
          }
        },
        'Cmd' => task.cmd.split(/\s(?=(?:[^']|'[^']*')*$)/)
      },
      slot.node.docker_connection
    )
    container.start

    task.update!(container_id: container.id, status: "started", slot: slot)
    slot.update!(status: "running", current_task: task, container_id: task.container_id)
    slot.node.update_usage

    task
  rescue StandardError, Excon::Error => e
    case e
    when Excon::Error then
      message = "Docker connection error: #{e.message}"
      slot.node.update(available: false)
    when Docker::Error::NotFoundError then
      message = "Docker image not found: #{e.message}"
    end

    slot.release
    task.update(error: message, slot: nil, container_id: nil)
    task.retry
  end
end
