# frozen_string_literal: true

require "rails_helper"

RSpec.describe LeastUsedNode, type: :service do
  subject { described_class.new(execution_type: execution_type).call }
  let(:execution_type) { "io" }

  let(:node1) { Fabricate(:node, name: "node1") }
  let(:node2) { Fabricate(:node, name: "node2") }
  let(:node3) { Fabricate(:node, name: "node3") }
  let(:node4) { Fabricate(:node, name: "node4", status: "unstable") }
  let(:node5) { Fabricate(:node, name: "node5", status: "unavailable") }
  let(:node6) { Fabricate(:node, name: "node6", accept_new_tasks: false) }

  let!(:slot1_1) { Fabricate(:slot_available, node: node1, name: "slot1_1", execution_type: "io") }
  let!(:slot1_2) { Fabricate(:slot_running, node: node1, name: "slot1_2", execution_type: "cpu") }
  let!(:slot1_3) { Fabricate(:slot_running, node: node1, name: "slot1_3", execution_type: "network") }
  let!(:slot1_4) { Fabricate(:slot_available, node: node1, name: "slot1_4", execution_type: "cpu") }
  let!(:slot1_5) { Fabricate(:slot_available, node: node1, name: "slot1_5", execution_type: "cpu") }
  let!(:slot1_6) { Fabricate(:slot_available, node: node1, name: "slot1_6", execution_type: "cpu") }
  let!(:slot1_7) { Fabricate(:slot_available, node: node1, name: "slot1_7", execution_type: "cpu") }
  let!(:slot1_8) { Fabricate(:slot_available, node: node1, name: "slot1_8", execution_type: "cpu") }

  let!(:slot2_1) { Fabricate(:slot_running, node: node2, name: "slot2_1", execution_type: "network") }
  let!(:slot2_2) { Fabricate(:slot_running, node: node2, name: "slot2_2", execution_type: "network") }
  let!(:slot2_3) { Fabricate(:slot_available, node: node2, name: "slot2_3", execution_type: "io") }
  let!(:slot2_4) { Fabricate(:slot_running, node: node2, name: "slot2_4", execution_type: "io") }

  let!(:slot3_1) { Fabricate(:slot_running, node: node3, name: "slot3_1", execution_type: "cpu") }
  let!(:slot3_2) { Fabricate(:slot_running, node: node3, name: "slot3_2", execution_type: "cpu") }
  let!(:slot3_3) { Fabricate(:slot_running, node: node3, name: "slot3_3", execution_type: "cpu") }
  let!(:slot3_4) { Fabricate(:slot_available, node: node3, name: "slot3_4", execution_type: "io") }
  let!(:slot3_5) { Fabricate(:slot_available, node: node3, name: "slot3_5", execution_type: "cpu") }
  let!(:slot3_6) { Fabricate(:slot_available, node: node3, name: "slot3_6", execution_type: "cpu") }

  let!(:slot4_1) { Fabricate(:slot_available, node: node4, name: "slot4_1", execution_type: "io") }
  let!(:slot4_2) { Fabricate(:slot_available, node: node4, name: "slot4_2", execution_type: "cpu") }
  let!(:slot4_3) { Fabricate(:slot_available, node: node4, name: "slot4_3", execution_type: "network") }

  let!(:slot5_1) { Fabricate(:slot_available, node: node5, name: "slot5_1", execution_type: "io") }
  let!(:slot5_2) { Fabricate(:slot_available, node: node5, name: "slot5_2", execution_type: "cpu") }
  let!(:slot5_3) { Fabricate(:slot_available, node: node5, name: "slot5_3", execution_type: "network") }

  let!(:slot6_1) { Fabricate(:slot_available, node: node6, name: "slot6_2", execution_type: "cpu") }

  context "with cpu execution_type" do
    let(:execution_type) { "cpu" }

    it "returns least used node with specific execution_type" do
      expect(subject).to eq(node1)
    end

    it "does not return a node that does not accept new tasks" do
      expect(subject).to_not eq(node6)
    end
  end

  context "with io execution_type" do
    let(:execution_type) { "io" }

    it "returns least used node with specific execution_type" do
      expect(subject).to be_in([node1, node3])
    end

    it "does not return most used nodes" do
      expect(subject).not_to eq(node2)
    end
  end

  context "with existent but busy execution type for all nodes" do
    let(:execution_type) { "network" }

    it "does not return any node" do
      expect(subject).to be_nil
    end
  end
end
