# frozen_string_literal: true

require "rails_helper"

RSpec.describe RemoveRunnerJob, type: :job do
  let(:node) { Node.create(hostname: "local.test") }
  let(:runner_id) { "11223344" }
  let(:docker_remove_runner_instance) { double(Runners::Docker::RemoveRunner) }

  before do
    allow(node).to receive(:runner_service)
      .with(:remove_runner)
      .and_return(docker_remove_runner_instance)
  end

  it "performs docker remove container" do
    expect(docker_remove_runner_instance).to receive(:perform)
      .with(node: node, runner_id: runner_id)

    subject.perform(node: node, runner_id: runner_id)
  end
end
