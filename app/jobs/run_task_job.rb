class RunTaskJob < ApplicationJob
  queue_as :default

  def perform(task:, slot:)
    @node = slot.node

    image_name, image_tag = task.image.split(':')
    Docker::Image.create({'fromImage' => image_name, 'tag' => image_tag}, nil, slot.node.docker_connection)

    binds = []
    binds << "/nfs:#{task.storage_mount}" if task.storage_mount.present?

    container = Docker::Container.create(
      {
        'Image' => task.image,
        'HostConfig' => {
          'Binds' => binds,
          'LogConfig' =>  {
            'Type' => 'fluentd',
            'Config' => {
              "tag" => "docker.{{.ID}}",
              "fluentd-sub-second-precision" => "true"
            }
          }
        },
        'Cmd' => task.cmd.split(/\s(?=(?:[^']|'[^']*')*$)/)
      },
      slot.node.docker_connection
    )
    container.start

    task.started!
    task.update!(container_id: container.id, slot: slot)

    slot.running!
    slot.update!(current_task: task, container_id: task.container_id)

    task
  rescue StandardError, Excon::Error => e
    case e
    when Excon::Error then
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
end
