# frozen_string_literal: true

require "rails_helper"

RSpec.describe NodeUsagePercentagePerExecutionType, type: :service do
  let(:node1) { Fabricate(:node, name: "node1") }

  before do
    Fabricate(:slot, node: node1, name: "slot1_1", execution_type: "io")
    Fabricate(:slot, node: node1, name: "slot1_3", execution_type: "io")
    Fabricate(:slot, node: node1, name: "slot1_4", execution_type: "network", status: "running")
    Fabricate(:slot, node: node1, name: "slot1_5", execution_type: "network")
    Fabricate(:slot, node: node1, name: "slot1_5", execution_type: "cpu", status: "running")
    Fabricate(:slot, node: node1, name: "slot1_6", execution_type: "cpu")
    Fabricate(:slot, node: node1, name: "slot1_7", execution_type: "cpu")
    Fabricate(:slot, node: node1, name: "slot1_8", execution_type: "cpu")
    Fabricate(:slot, node: node1, name: "slot1_9", execution_type: "cpu")
  end

  context "with a given node" do
    it "returns the percentage for the slots of the node" do
      expect(described_class.new(node1).perform).to contain_exactly(
        { execution_type: "cpu", usage_percent: 20 },
        { execution_type: "io", usage_percent: 0 },
        execution_type: "network", usage_percent: 50
      )
    end
  end
end
