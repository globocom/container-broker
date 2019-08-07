require 'rails_helper'

RSpec.describe Node, type: :model do
  subject { Fabricate.build(:node) }

  context "registering error" do
    context "when node was available" do
      subject { Fabricate.build(:node, status: "available", last_error: nil) }

      it "updates node status" do
        expect { subject.register_error("generic error") }.to change(subject, :status).to("unstable")
      end
    end

    context "when node was unstable" do
      subject { Fabricate.build(:node, status: "unstable", last_error: nil, last_success_at: last_success_at) }

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

    context "when node was unavailable" do
      subject { Fabricate.build(:node, status: "unavailable", last_error: nil) }

      it "keeps node as unavailable" do
        expect { subject.register_error("generic error") }.to_not change(subject, :status).from("unavailable")
      end
    end
  end

  context "validate slots execution types" do
    context "when valid" do
      it "returns valid" do
        expect(subject.valid?).to be_truthy
      end
    end

    context "when invalid" do
      subject{ Fabricate.build(:node, slots_execution_types: { io: 10, cpu_: 2 }) }

      it "returns invalid" do
        expect(subject.valid?).to be_falsey
      end
    end
  end
end
