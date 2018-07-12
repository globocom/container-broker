require 'rails_helper'

RSpec.describe Node, type: :model do

  context "updating usage" do
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

  context "populating slots" do
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

  context "registering error" do
    context "when node was available" do
      subject { described_class.new(status: "available", last_error: nil) }
      it "updates node status" do
        expect { subject.register_error("generic error") }.to change(subject, :status).to("unstable")
      end
    end

    context "when node was unstable" do
      subject { described_class.new(status: "unstable", last_error: nil, last_success_at: last_success_at) }

      before { allow(Settings).to receive(:node_unavailable_after_seconds).and_return(10.minutes) }

      context "for less than the allowed time" do
        let(:last_success_at) { Time.zone.now - 1.minute }

        it "does not change node status" do
          expect { subject.register_error("generic error") }.to_not change(subject, :status)
        end
      end

      context "for more than the allowed time" do
        let(:last_success_at) { Time.zone.now - 15.minutes }

        it "changes node status to unavailable" do
          expect { subject.register_error("generic error") }.to change(subject, :status).to("unavailable")
        end

        it "migrate running tasts to another node" do
          subject.register_error("generic error")
          expect(MigrateTasksFromDeadNodeJob).to have_been_enqueued.with(node: subject)
        end
      end
    end
  end
end
