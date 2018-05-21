require 'rails_helper'

RSpec.describe Node, type: :model do

  describe "#update_usage" do
    before do
      Slot.create(node: subject, status: "running")
      Slot.create(node: subject, status: "attaching")
      Slot.create(node: subject, status: "idle")
      Slot.create(node: subject, status: "releasing")
    end

    it "sets usage to percentual of used slots" do
      subject.update_usage
      expect(subject.usage_percent).to eq(75)
    end
  end

  describe ".available" do
    before do
      Node.create!(available: true)
      Node.create!(available: true)
      Node.create!(available: false)
      Node.create!(available: true)
    end

    it "returns only available slots" do
      expect(described_class.available).to have(3).nodes
    end
  end

  describe "#populate" do
    it "calls node naming" do
      expect_any_instance_of(FriendlyNameNodes).to receive(:call)
      subject.populate
    end

    it "calls update usage" do
      expect(subject).to receive(:update_usage)
      subject.populate
    end

    context "when there is more nodes than cores" do
      before do
        8.times {Slot.create!(node: subject)}
        subject.update!(cores: 2)
      end

      it "removes extra nodes" do
        subject.populate
        expect(subject.slots.count).to eq(2)
      end
    end

    context "when there is less nodes than cores" do
      before do
        2.times {Slot.create!(node: subject)}
        subject.update!(cores: 8)
      end

      it "creates remaining nodes" do
        subject.populate
        expect(subject.slots.count).to eq(8)
      end
    end
  end

  describe "#available!" do
    subject { described_class.new(available: false, last_error: "generic error") }

    it "updates available to true" do
      expect { subject.available! }.to change(subject, :available).to(true)
    end

    it "clears last_error" do
      expect { subject.available! }.to change(subject, :last_error).to(nil)
    end
  end

  describe "#unavailable!" do
    subject { described_class.new(available: true, last_error: nil) }

    it "updates available to false" do
      expect { subject.unavailable! }.to change(subject, :available).to(false)
    end

    it "clears last_error" do
      expect { subject.unavailable!(error: "generic error") }.to change(subject, :last_error).to("generic error")
    end
  end
end
