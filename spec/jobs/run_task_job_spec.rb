# frozen_string_literal: true

require "rails_helper"

RSpec.describe RunTaskJob, type: :job do
  let(:node) { Fabricate(:node) }
  let(:task) do
    Task.create!(
      name: "task-name",
      image: "busybox",
      cmd: "-i input.txt -metadata comment='Encoded by Globo.com' output.mp4",
      storage_mount: "/tmp/workdir",
      ingest_storage_mount: "/ingest",
      execution_type: "test"
    )
  end
  let(:slot) { Fabricate(:slot_attaching, node: node, execution_type: "test") }
  let(:docker_task_runner_instance) { double(Runners::Docker::RunTask) }

  before do
    allow(Runners::ServicesFactory).to receive(:fabricate)
      .with(runner: node.runner, service: :run_task)
      .and_return(docker_task_runner_instance)
  end

  it "performs docker run task" do
    expect(docker_task_runner_instance).to receive(:perform).with(task: task, slot: slot)

    subject.perform(task: task, slot: slot)
  end
end
