# frozen_string_literal: true

require "rails_helper"

RSpec.describe AdjustExecutionTypeSlots, type: :service do
  let(:slots_execution_types) { { "io" => amount_io, "cpu" => amount_cpu } }
  let(:node) { Fabricate(:node, slots_execution_types: slots_execution_types) }
  let(:amount_io) { "<defined-in-each-context>" }
  let(:amount_cpu) { "<defined-in-each-context>" }
  let(:friendly_name_slots_instance) { double("FriendlyNameSlots", perform: true) }

  before do
    allow(FriendlyNameSlots).to receive(:new).and_return(friendly_name_slots_instance)
  end

  context "when slots need to be incremented" do
    let(:amount_io) { 2 }
    let(:amount_cpu) { 3 }

    it "increments io slots to desired number" do
      expect do
        described_class.new(node: node, execution_type: "io").perform
      end.to change { node.slots.count }.by(2)
    end

    it "increments cpu slots to desired number" do
      expect do
        described_class.new(node: node, execution_type: "cpu").perform
      end.to change { node.slots.count }.by(3)
    end

    it "calls node naming" do
      expect(friendly_name_slots_instance).to receive(:perform)

      described_class.new(node: node, execution_type: "cpu").perform
    end
  end

  context "when slots need to be decremented" do
    context "and there are are io idle slots enough" do
      let(:amount_io) { 0 }
      let!(:slots) { Fabricate.times(2, :slot_idle, node: node, execution_type: "io") }

      it "decrements slots to desired number" do
        expect do
          described_class.new(node: node, execution_type: "io").perform
        end.to change { node.slots.count }.by(-2)
      end
    end

    context "and there are not io idle slots enough" do
      let(:amount_io) { 0 }

      context "and there are none idle slots" do
        before do
          Fabricate.times(2, :slot_running, node: node, execution_type: "io")
        end

        it "does not decrement slots to desired number" do
          expect do
            described_class.new(node: node, execution_type: "io").perform
          end.to_not change { node.slots.count }
        end
      end

      context "and there are some idle slots" do
        before do
          Fabricate(:slot_idle, node: node, execution_type: "io")
          Fabricate(:slot_running, node: node, execution_type: "io")
        end

        it "does not decrement slots to desired number" do
          expect do
            described_class.new(node: node, execution_type: "io").perform
          end.to change { node.slots.count }.by(-1)
        end
      end
    end
  end
end
