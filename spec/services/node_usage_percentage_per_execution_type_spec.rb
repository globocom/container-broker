require 'rails_helper'

RSpec.describe NodeUsagePercentagePerExecutionType, type: :service do
  let(:node1) { Fabricate(:node, name: "node1") }

  let!(:slot1_1) { Fabricate(:slot, node: node1, name: "slot1_1", execution_type: "io") }
  let!(:slot1_2) { Fabricate(:slot, node: node1, name: "slot1_3", execution_type: "io") }
  let!(:slot1_3) { Fabricate(:slot, node: node1, name: "slot1_4", execution_type: "network", status: "running") }
  let!(:slot1_4) { Fabricate(:slot, node: node1, name: "slot1_5", execution_type: "network") }
  let!(:slot1_5) { Fabricate(:slot, node: node1, name: "slot1_5", execution_type: "cpu", status: "running") }
  let!(:slot1_6) { Fabricate(:slot, node: node1, name: "slot1_6", execution_type: "cpu") }
  let!(:slot1_7) { Fabricate(:slot, node: node1, name: "slot1_7", execution_type: "cpu") }
  let!(:slot1_8) { Fabricate(:slot, node: node1, name: "slot1_8", execution_type: "cpu") }
  let!(:slot1_9) { Fabricate(:slot, node: node1, name: "slot1_9", execution_type: "cpu") }

  context "with a given node" do
    it "returns the percentage for the slots of the node" do
      expect(described_class.new(node1).perform).to contain_exactly(
        { execution_type: "cpu", usage_percent: 20 },
        { execution_type: "io", usage_percent: 0 },
        { execution_type: "network", usage_percent: 50 }
      )
    end
  end
end
