require 'rails_helper'

RSpec.describe UpdateNodeStatusJob, type: :job do
  let(:node) { Fabricate(:node) }
  let(:containers) { [] }

  before do
    allow(Docker::Container).to receive(:all).and_return(containers)
    allow(Docker).to receive(:info).and_return("SystemTime" => Time.zone.now.to_s)
  end

  context "for all containers" do
    let(:containers) { [container] }
    let(:container_id) { SecureRandom.hex }
    let(:container_creation_date) { 2.minutes.ago.to_s.to_i }
    let(:container) { double("Docker::Container", id: container_id, info: {"State" => container_state, "Names" => [], "Created" => container_creation_date})}
    let(:container_state) { "" }

    let!(:slot) { Fabricate(:slot_running, node: node, container_id: container_id) }

    context "when a slot is found with that container id" do
      context "and the container status is exited" do
        let(:container_state) { "exited" }

        context "and the slot is running" do
          it "marks slot as releasing" do
            expect do
              subject.perform(node: node)
              slot.reload
            end.to change(slot, :status).to("releasing")
          end

          it "enqueues slot releasing job" do
            subject.perform(node: node)
            expect(ReleaseSlotJob).to have_been_enqueued.with(slot: slot)
          end
        end
      end

      context "and the container status is running" do
        let(:container_state) { "running" }

        it "keeps slot as running" do
          expect do
            subject.perform(node: node)
            slot.reload
          end.to_not change(slot, :status)
        end

        it "does not enqueue slot releasing job" do
          subject.perform(node: node)
          expect(ReleaseSlotJob).to_not have_been_enqueued.with(slot: slot)
        end
      end
    end
  end

  context "when UpdateNodeStatusJob is locked" do
    let(:lock_manager) do
      LockManager.new(
        type: "update-node-status",
        id: node.id,
        expire: 1.minute,
        wait: true
      )
    end

    before { lock_manager.lock! }
    after { lock_manager.unlock! }

    it "does not update the node" do
      subject.perform(node: node)
      expect(subject).to_not receive(:update_node_status)
    end
  end

  context "when UpdateNodeStatusJob is not locked" do
    it "updates the node" do
      expect(subject).to receive(:update_node_status)

      subject.perform(node: node)
    end
  end
end
