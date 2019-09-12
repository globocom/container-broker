# frozen_string_literal: true

require "rails_helper"

RSpec.describe CheckForSlotRemoval, type: :service do
  let(:adjust_execution_type_slots_service) { double(AdjustExecutionTypeSlots) }
  let(:slot) { Fabricate(:slot) }
  let(:decrement) { "<defined-in-each-context>" }

  subject { CheckForSlotRemoval.new(slot: slot) }

  before do
    allow(AdjustExecutionTypeSlots).to receive(:new)
      .with(node: slot.node, execution_type: slot.execution_type)
      .and_return(adjust_execution_type_slots_service)

    allow(adjust_execution_type_slots_service).to receive(:decrement?).and_return(decrement)
  end

  context "when need to remove" do
    let(:decrement) { true }

    it "removes the slot" do
      expect { subject.perform }.to change { Slot.find(slot.id) }.from(slot).to(nil)
    end

    it "can check if is removed" do
      subject.perform
      expect(subject).to be_removed
    end
  end

  context "when don't need to remove" do
    let(:decrement) { false }

    it "doesn't remove the slot" do
      expect { subject.perform }.to_not change { Slot.count }
    end

    it "can check if is removed" do
      subject.perform
      expect(subject).to_not be_removed
    end
  end
end
