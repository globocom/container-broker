# frozen_string_literal: true

require "rails_helper"

RSpec.describe UpdateNodeStatusJob, type: :job do
  let(:node) { Fabricate(:node) }
  let(:docker_runner_instance) { double(Runners::Docker::UpdateNodeStatus) }

  before do
    allow(Runners::ServicesFactory).to receive(:fabricate).with(node: node, service: :update_node_status).and_return(docker_runner_instance)
  end

  context "when UpdateNodeStatusJob is locked" do
    let(:lock_manager) do
      LockManager.new(
        type: described_class.to_s,
        id: node.id,
        expire: 1.minute,
        wait: true
      )
    end

    before { lock_manager.lock! }
    after { lock_manager.unlock! }

    it "does not update the node" do
      subject.perform(node: node)

      expect(docker_runner_instance).to_not receive(:perform)
    end
  end

  context "when UpdateNodeStatusJob is not locked" do
    it "updates the node" do
      expect(docker_runner_instance).to receive(:perform)

      subject.perform(node: node)
    end
  end
end
