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
        'Cmd' => task.cmd.split(' ')
      },
      slot.node.docker_connection
    )
    container.start

    task.update!(container_id: container.id, status: "started", slot: slot)
    slot.attach_to(task: task)
    slot.node.update_usage

    task
  end
end
