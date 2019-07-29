require 'rails_helper'

RSpec.describe UpdateNodeStatusJob, type: :job do
  let(:node) { Fabricate(:node) }

  before do
    allow(Docker::Container).to receive(:all).and_return([])
  end

  context "when UpdateNodeStatusJob is locked" do
    let(:lock_manager) do
      LockManager.new(
        type: "update-node-status",
        id: node.id,
        expire: 1.minute,
        wait: true
      )
    end

    before { lock_manager.lock! }
    after { lock_manager.unlock! }

    it "does not update the node" do
      subject.perform(node: node)
      expect(subject).to_not receive(:update_node_status)
    end
  end

  context "when UpdateNodeStatusJob is not locked" do
    it "updates the node" do
      expect(subject).to receive(:update_node_status)

      subject.perform(node: node)
    end
  end
end
