class UpdateTaskStatusJob < DockerConnectionJob
  queue_as :default

  def perform(task)
    @node = task.slot.node

    container = Docker::Container.get(task.container_id, {all: true}, task.slot.node.docker_connection)

    status = container.info["State"]["Status"]
    exit_code = container.info["State"]["ExitCode"]

    task.started_at = container.info["State"]["StartedAt"]

    if status == 'exited'
      task.exit_code = exit_code
      task.finished_at = container.info["State"]["FinishedAt"]

      if exit_code.zero?
        task.completed!
        task.error = nil
      else
        task.error = container.info["State"]["Error"]
        task.retry
      end
    else
      task.running!
    end

    task.save
  end
end
