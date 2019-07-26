require 'rails_helper'

RSpec.describe LeastUsedNode, type: :service do
  subject { described_class.new(execution_type: execution_type).call }
  let(:execution_type) { "io" }

  let!(:node1) { Fabricate(:node, name: "node1") }
  let!(:node2) { Fabricate(:node, name: "node2") }
  let!(:node3) { Fabricate(:node, name: "node3") }
  let!(:node4) { Fabricate(:node, name: "node4", status: "unstable") }
  let!(:node5) { Fabricate(:node, name: "node5", status: "unavailable") }

  let!(:slot1_1) { Fabricate(:slot, node: node1, name: "slot1_1", execution_type: "io") }
  let!(:slot1_2) { Fabricate(:slot, node: node1, name: "slot1_2", execution_type: "cpu", status: "running") }
  let!(:slot1_3) { Fabricate(:slot, node: node1, name: "slot1_3", execution_type: "network", status: "running") }
  let!(:slot1_4) { Fabricate(:slot, node: node1, name: "slot1_4", execution_type: "cpu") }
  let!(:slot1_5) { Fabricate(:slot, node: node1, name: "slot1_5", execution_type: "cpu") }
  let!(:slot1_6) { Fabricate(:slot, node: node1, name: "slot1_6", execution_type: "cpu") }
  let!(:slot1_7) { Fabricate(:slot, node: node1, name: "slot1_7", execution_type: "cpu") }
  let!(:slot1_8) { Fabricate(:slot, node: node1, name: "slot1_8", execution_type: "cpu") }

  let!(:slot2_1) { Fabricate(:slot, node: node2, name: "slot2_1", execution_type: "network", status: "running") }
  let!(:slot2_2) { Fabricate(:slot, node: node2, name: "slot2_2", execution_type: "network", status: "running") }
  let!(:slot2_3) { Fabricate(:slot, node: node2, name: "slot2_3", execution_type: "io") }
  let!(:slot2_4) { Fabricate(:slot, node: node2, name: "slot2_4", execution_type: "io", status: "running") }

  let!(:slot3_1) { Fabricate(:slot, node: node3, name: "slot3_1", execution_type: "cpu", status: "running") }
  let!(:slot3_2) { Fabricate(:slot, node: node3, name: "slot3_2", execution_type: "cpu", status: "running") }
  let!(:slot3_3) { Fabricate(:slot, node: node3, name: "slot3_3", execution_type: "cpu", status: "running") }
  let!(:slot3_4) { Fabricate(:slot, node: node3, name: "slot3_4", execution_type: "io") }
  let!(:slot3_5) { Fabricate(:slot, node: node3, name: "slot3_5", execution_type: "cpu") }
  let!(:slot3_6) { Fabricate(:slot, node: node3, name: "slot3_6", execution_type: "cpu") }

  let!(:slot4_1) { Fabricate(:slot, node: node4, name: "slot4_1", execution_type: "io") }
  let!(:slot4_2) { Fabricate(:slot, node: node4, name: "slot4_2", execution_type: "cpu") }
  let!(:slot4_3) { Fabricate(:slot, node: node4, name: "slot4_3", execution_type: "network") }

  let!(:slot5_1) { Fabricate(:slot, node: node5, name: "slot5_1", execution_type: "io") }
  let!(:slot5_2) { Fabricate(:slot, node: node5, name: "slot5_2", execution_type: "cpu") }
  let!(:slot5_3) { Fabricate(:slot, node: node5, name: "slot5_3", execution_type: "network") }

  context "with cpu execution_type" do
    let(:execution_type) { "cpu" }

    it "returns least used node with specific execution_type" do

      expect(subject).to eq(node1)
    end
  end

  context "with io execution_type" do
    let(:execution_type) { "io" }

    it "does not return most used nodes" do
      expect(subject).not_to eq(node2)
    end

    context "and there are 2 nodes with the same usage for the specific execution type" do
      it "returns first of the least used nodes" do
        expect(subject).to eq(node1)
      end
    end
  end

  context "with existent but busy execution type for all nodes" do
    let(:execution_type) { "network" }

    it "does not return any node" do
      expect(subject).to be_nil
    end
  end
end

