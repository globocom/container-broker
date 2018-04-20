class RunTaskJob < DockerConnectionJob
  queue_as :default

  def perform(task:, slot:)
    @node = slot.node

    image_name, image_tag = task.image.split(':')
    Docker::Image.create({'fromImage' => image_name, 'tag' => image_tag}, nil, slot.node.docker_connection)
    container = Docker::Container.create(
      {
        'Image' => task.image,
        'HostConfig' => {
          'Binds' => ['/root/ef-shared:/tmp/workdir']
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
  rescue StandardError => e
    slot.release
    task.update(error: e.message, slot: nil, container_id: nil)
    task.retry
  end
end
