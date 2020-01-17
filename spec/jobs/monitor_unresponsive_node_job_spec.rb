# frozen_string_literal: true

require "rails_helper"

RSpec.describe MonitorUnresponsiveNodeJob, type: :job do
  let(:node) { Fabricate(:node) }
  let(:docker_monitor_unresponsive_node_instance) { double(Runners::Docker::MonitorUnresponsiveNode) }

  before do
    allow(Runners::ServicesFactory).to receive(:fabricate)
      .with(runner: node.runner, service: :monitor_unresponsive_node)
      .and_return(docker_monitor_unresponsive_node_instance)
  end

  it "performs docker monitor unresponsive node" do
    expect(docker_monitor_unresponsive_node_instance).to receive(:perform).with(node: node)

    subject.perform(node: node)
  end
end
