require 'rails_helper'

RSpec.describe UpdateAllNodesStatusJob, type: :job do
  let(:node_available_1) { Fabricate(:node, status: "available") }
  let(:node_unstable) { Fabricate(:node, status: "unstable") }
  let(:node_available_2) { Fabricate(:node, status: "available") }
  let(:node_unavailable) { Fabricate(:node, status: "unavailable") }

  let!(:nodes) { [node_available_1, node_unstable, node_available_2] }

  before { subject.perform }

  it "schedule UpdateNodeStatusJob for every available node" do
    expect(UpdateNodeStatusJob).to have_been_enqueued.with(node: node_available_1)
    expect(UpdateNodeStatusJob).to have_been_enqueued.with(node: node_available_2)
  end

  context "does not schedule UpdateNodeStatusJob" do
    it "for unavailable nodes" do
      expect(UpdateNodeStatusJob).to_not have_been_enqueued.with(node: node_unstable)
    end

    it "for unstable nodes" do
      expect(UpdateNodeStatusJob).to_not have_been_enqueued.with(node: node_unavailable)
    end
  end
end
