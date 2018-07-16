require 'rails_helper'

RSpec.describe MonitorUnresponsiveNodesJob, type: :job do
  let!(:available_node) { Node.create!(status: "available") }
  let!(:unstable_node) { Node.create!(status: "unstable") }
  let!(:unavailable_node) { Node.create!(status: "unavailable") }

  it "enqueues MonitorUnresponsiveNodeJob for unavailable nodes" do
    subject.perform
    expect(MonitorUnresponsiveNodeJob).to have_been_enqueued.with(node: unavailable_node)
  end

  it "enqueues MonitorUnresponsiveNodeJob for unstable nodes" do
    subject.perform
    expect(MonitorUnresponsiveNodeJob).to have_been_enqueued.with(node: unstable_node)
  end

  it "does not enqueue MonitorUnresponsiveNodeJob for available nodes" do
    subject.perform
    expect(MonitorUnresponsiveNodeJob).to_not have_been_enqueued.with(node: available_node)
  end
end
