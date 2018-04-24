class UpdateTaskStatusJob < DockerConnectionJob
  queue_as :default

  def perform(task)
    @node = task.slot.node

    container = Docker::Container.get(task.container_id, {all: true}, task.slot.node.docker_connection)

    status = container.info["State"]["Status"]
    exit_code = container.info["State"]["ExitCode"]

    if status == 'exited'
      if exit_code.zero?
        task.completed!
        task.error = nil
      else
        task.error = container.info["State"]["Error"]
        task.retry
      end

      task.exit_code = exit_code
      task.finished_at = container.info["State"]["FinishedAt"]
    else
      task.status = status
    end

    task.started_at = container.info["State"]["StartedAt"]

    task.save
  end
end
