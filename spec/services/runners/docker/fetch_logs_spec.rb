# frozen_string_literal: true

require "rails_helper"

RSpec.describe Runners::Docker::FetchLogs, type: :service do
  let(:node) { Fabricate(:node) }
  let(:slot) { Fabricate(:slot, node: node) }
  let(:task) { Fabricate(:task, slot: slot) }
  let(:container_instance) { double(::Docker::Container, streaming_logs: "test logs") }

  before do
    allow_any_instance_of(Runners::Docker::FetchTaskContainer).to receive(:perform)
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
