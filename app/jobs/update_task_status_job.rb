class UpdateTaskStatusJob < DockerConnectionJob
  queue_as :default

  def perform(task)
    @node = task.slot.node

    container = Docker::Container.get(task.container_id, {all: true}, task.slot.node.docker_connection)

    status = container.info["State"]["Status"]
    exit_code = container.info["State"]["ExitCode"]

    if status == 'exited'
      if exit_code.zero?
        task.status = 'completed'
        task.error = nil
      else
        task.retry
      end

      logs =  container.logs(stdout: true, stderr: true)
      logs.gsub!(/[\x00-\x09]/, "")
      puts logs
      task.set_error_log(logs)

      task.exit_code = exit_code
    else
      task.status = status
    end

    task.error = container.info["State"]["Error"]
    task.started_at = container.info["State"]["StartedAt"]
    task.finished_at = container.info["State"]["FinishedAt"]

    #todo: create progress type
    task.progress = get_progress(container: container)

    task.save
  end

  def get_progress(container:)
    lines = container.logs(stderr: true, stdout: true, tail: 5).split("\r")
    regexp = / time=(\d{2}:\d{2}:\d{2}\.\d{2})/
    progress_line = lines.reverse.find {|line| line =~ regexp }

    if progress_line
      progress_line.match(regexp).captures.first
    else
      "00:00:00.00"
    end
  end
end
