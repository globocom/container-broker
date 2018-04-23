require 'rails_helper'

RSpec.describe UpdateAllNodesStatusJob, type: :job do
  let(:node1) { Node.create!(available: true) }
  let(:node2) { Node.create!(available: false) }
  let(:node3) { Node.create!(available: true) }

  let!(:nodes) { [node1, node2, node3] }

  it "schedule UpdateNodeStatusJob for every available node" do
    subject.perform

    expect(UpdateNodeStatusJob).to have_been_enqueued.with(node: node1)
    expect(UpdateNodeStatusJob).to have_been_enqueued.with(node: node3)

    expect(UpdateNodeStatusJob).to_not have_been_enqueued.with(node: node2)
  end
end
