require 'rails_helper'

RSpec.describe MonitorUnresponsiveNodesJob, type: :job do
  let!(:available_node) { Node.create!(available: true) }
  let!(:unavailable_node) { Node.create!(available: false) }

  it "enqueues MonitorUnresponsiveNodeJob for unavailable nodes" do
    subject.perform
    expect(MonitorUnresponsiveNodeJob).to have_been_enqueued.with(node: unavailable_node)
  end

  it "does not enqueue MonitorUnresponsiveNodeJob for available nodes" do
    subject.perform
    expect(MonitorUnresponsiveNodeJob).to_not have_been_enqueued.with(node: available_node)
  end
end
