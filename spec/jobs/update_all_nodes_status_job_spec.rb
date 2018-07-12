require 'rails_helper'

RSpec.describe UpdateAllNodesStatusJob, type: :job do
  let(:node1) { Fabricate(:node, status: "available") }
  let(:node2) { Fabricate(:node, status: "unstable") }
  let(:node3) { Fabricate(:node, status: "available") }
  let(:node4) { Fabricate(:node, status: "unavailable") }

  let!(:nodes) { [node1, node2, node3] }

  before { subject.perform }

  it "schedule UpdateNodeStatusJob for every available node" do
    expect(UpdateNodeStatusJob).to have_been_enqueued.with(node: node1)
    expect(UpdateNodeStatusJob).to have_been_enqueued.with(node: node3)
  end

  context "does not schedule UpdateNodeStatusJob" do
    it "for unavailable nodes" do
      expect(UpdateNodeStatusJob).to_not have_been_enqueued.with(node: node2)
    end

    it "for unstable nodes" do
      expect(UpdateNodeStatusJob).to_not have_been_enqueued.with(node: node4)
    end
  end
end
