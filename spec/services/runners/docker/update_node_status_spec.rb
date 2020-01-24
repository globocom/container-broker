# frozen_string_literal: true

require "rails_helper"

RSpec.describe Runners::Docker::UpdateNodeStatus, type: :service do
  let(:node) { Fabricate(:node) }
  let(:containers) { [] }

  before do
    allow(Docker::Container).to receive(:all).and_return(containers)
    allow(Docker).to receive(:info).and_return("SystemTime" => Time.zone.now.to_s)
  end

  context "for all containers" do
    let(:containers) { [container] }
    let(:runner_id) { SecureRandom.hex }
    let(:container_creation_date) { 2.minutes.ago.to_s.to_i }
    let(:runner_id) { "runner-123" }
    let(:container) do
      double(
        "Docker::Container",
        id: runner_id,
        info: {
          "State" => container_state,
          "Names" => ["other-container-name", "/runner-123"],
          "Created" => container_creation_date
        }
      )
    end

    let(:container_state) { "" }

    let!(:slot) { Fabricate(:slot_running, node: node, runner_id: runner_id) }

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
            expect(ReleaseSlotJob).to have_been_enqueued.with(slot: slot, runner_id: runner_id)
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

    context "reschedules tasks when container is missing" do
      let(:reschedule_tasks_for_missing_containers_service) { double("RescheduleTasksForMissingContainers") }
      let(:started_tasks) { [Fabricate(:running_task, slot: slot)] }

      before do
        allow(RescheduleTasksForMissingContainers).to receive(:new)
          .with(started_tasks: started_tasks, runner_ids: contain_exactly("runner-123", "other-container-name"))
          .and_return(reschedule_tasks_for_missing_containers_service)
      end

      it "calls RescheduleTasksForMissingContainers perform" do
        expect(reschedule_tasks_for_missing_containers_service).to receive(:perform)
        subject.perform(node: node)
      end
    end
  end
end
