require 'rails_helper'

RSpec.describe LockSlot, type: :service do

  let(:execution_type) { "cpu" }

  let(:node1) { Fabricate(:node) }
  let(:node2) { Fabricate(:node) }

  context "with available slots for execution_type" do
    let!(:slot1_1) { Fabricate(:slot_idle, node: node1, execution_type: execution_type) }
    let!(:slot2_1) { Fabricate(:slot_idle, node: node2, execution_type: execution_type) }
    let!(:slot2_2) { Fabricate(:slot_running, node: node2, execution_type: execution_type) }

    subject { described_class.new(execution_type: execution_type) }

    it "returns the correct slot" do
      expect(subject.first_available).to eq(slot1_1)
    end

    it "allocates slot" do
      subject.perform

      expect(slot1_1.reload).to be_attaching
    end
  end

  context "with no available slots for execution_type" do
    let!(:slot1_1) { Fabricate(:slot_running, node: node1, execution_type: execution_type) }
    let!(:slot2_1) { Fabricate(:slot_running, node: node2, execution_type: execution_type) }
    let!(:slot2_2) { Fabricate(:slot_running, node: node2, execution_type: execution_type) }

    subject { described_class.new(execution_type: execution_type) }

    it "returns nil" do
      expect(subject.first_available).to be_nil
    end

    it "allocates slot" do
      expect(subject.perform).to be_nil
    end
  end

  context "with a node is specified" do
    let!(:slot1_1) { Fabricate(:slot_idle, node: node1, execution_type: execution_type) }
    let!(:slot2_1) { Fabricate(:slot_idle, node: node2, execution_type: execution_type) }
    let!(:slot2_2) { Fabricate(:slot_running, node: node2, execution_type: execution_type) }

    subject { described_class.new(execution_type: execution_type, node: node2) }

    it "returns a slot of specified node" do
      expect(subject.first_available).to eq(slot2_1)
    end

    it "allocates slot" do
      subject.perform

      expect(slot2_1.reload).to be_attaching
    end
  end
end
