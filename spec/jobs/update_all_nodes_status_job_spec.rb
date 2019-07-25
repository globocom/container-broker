require 'rails_helper'

RSpec.describe UpdateAllNodesStatusJob, type: :job do
  let(:node_available_1) { Fabricate(:node, status: "available") }
  let(:node_unstable) { Fabricate(:node, status: "unstable") }
  let(:node_available_2) { Fabricate(:node, status: "available") }
  let(:node_unavailable) { Fabricate(:node, status: "unavailable") }

  let!(:nodes) { [node_available_1, node_unstable, node_available_2] }


  it "schedule UpdateNodeStatusJob for every available node" do
    subject.perform

    expect(UpdateNodeStatusJob).to have_been_enqueued.with(node: node_available_1)
    expect(UpdateNodeStatusJob).to have_been_enqueued.with(node: node_available_2)
  end

  context "does not schedule UpdateNodeStatusJob" do
    it "for unavailable nodes" do
      subject.perform

      expect(UpdateNodeStatusJob).to_not have_been_enqueued.with(node: node_unstable)
    end

    it "for unstable nodes" do
      subject.perform

      expect(UpdateNodeStatusJob).to_not have_been_enqueued.with(node: node_unavailable)
    end
  end

  context "when UpdateNodeStatusJob is locked" do
    let(:lock_manager) do
      LockManager.new(
        type: "update-node-status",
        id: node_available_1.id,
        expire: 1.minute,
        wait: true
      )
    end

    before { lock_manager.lock! }
    after { lock_manager.unlock! }

    it "does not enqueue another job" do
      subject.perform
      expect(UpdateNodeStatusJob).to_not have_been_enqueued.with(node: node_available_1)
    end

    it "enqueues not locked nodes" do
      subject.perform
      expect(UpdateNodeStatusJob).to have_been_enqueued.with(node: node_available_2)
    end
  end
end
