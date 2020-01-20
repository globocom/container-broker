# frozen_string_literal: true

require "rails_helper"

RSpec.describe Runners::Docker::FetchLogs, type: :service do
  let(:node) { Fabricate(:node) }
  let(:slot) { Fabricate(:slot, node: node) }
  let(:task) { Fabricate(:task, slot: slot) }
  let(:docker_fetch_task_container_instance) { double(Runners::Docker::FetchTaskContainer) }
  let(:container_instance) { double(::Docker::Container, streaming_logs: "test logs") }

  before do
    allow(Runners::ServicesFactory).to receive(:fabricate)
      .with(runner: node.runner, service: :fetch_task_container)
      .and_return(docker_fetch_task_container_instance)

    allow(docker_fetch_task_container_instance).to receive(:perform)
      .with(task: task)
      .and_return(container_instance)
  end

  it "performs streaming logs" do
    expect(container_instance).to receive(:streaming_logs)
      .with(stdout: true, stderr: true, tail: 1_000)
      .and_return(container_instance)

    subject.perform(task: task)
  end
end
