# frozen_string_literal: true

require 'rails_helper'

RSpec.describe SlotsUsagePercentage, type: :service do
  let(:idle_slot1) { Fabricate(:slot, name: "slot1") }
  let(:idle_slot2) { Fabricate(:slot, name: "slot2") }
  let(:busy_slot1) { Fabricate(:slot, name: "slot3", status: "running") }
  let(:busy_slot2) { Fabricate(:slot, name: "slot4", status: "running") }

  context "with busy and idle slots" do
    context "and decimal result" do
      let(:slots) { [idle_slot1, idle_slot2, busy_slot1] }

      it "returns the usage percentage" do
        expect(described_class.new(slots).perform).to eq(33.33)
      end
    end

    context "and integer result" do
      let(:slots) { [idle_slot1, busy_slot1] }

      it "returns the usage percentage" do
        expect(described_class.new(slots).perform).to eq(50)
      end

    end
  end

  context "with only available slots" do
    let(:slots) { [idle_slot1, idle_slot2] }

    it "returns the usage percentage" do
      expect(described_class.new(slots).perform).to eq(0)
    end
  end

  context "with only busy slots" do
    let(:slots) { [busy_slot1, busy_slot2] }

    it "returns the usage percentage" do
      expect(described_class.new(slots).perform).to eq(100)
    end
  end
end
