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
    let(:container_creation_date) { 2.minutes.ago.to_s.to_i }
    let(:runner_id) { "runner-123" }
    let(:container) do
      double(
        "Docker::Container",
        id: SecureRandom.hex,
        info: {
          "State" => container_state,
          "Names" => [runner_id],
          "Created" => container_creation_date
        }
      )
    end

    let(:container_state) { "" }

    let!(:slot) { Fabricate(:slot_running, node: node, runner_id: runner_id) }

    context "when a slot is found with that container name" do
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

      context "and the container status is created" do
        let(:container_state) { "created" }
        let(:docker_connection) { double(::Docker::Connection) }

        before do
          allow(Docker::Container).to receive(:get)
            .with(container.id, { all: true }, docker_connection)
            .and_return(
              double(
                info: {
                  "State" => {
                    "ExitCode" => exit_code
                  }
                }
              )
            )
          allow_any_instance_of(Runners::Docker::CreateConnection).to receive(:perform).with(node: node).and_return(docker_connection)
        end

        context "and it has exit code zero" do
          let(:exit_code) { 0 }

          it "does not try to start the container again" do
            expect(container).to_not receive(:start)
            subject.perform(node: node)
          end
        end

        context "and it has exit code different than zero" do
          let(:exit_code) { 127 }

          it "tries to start the container again" do
            expect(container).to receive(:start)
            subject.perform(node: node)
          end
        end
      end
    end

    context "reschedules tasks when container is missing" do
      let(:reschedule_tasks_for_missing_containers_service) { double("RescheduleTasksForMissingRunners") }
      let!(:started_tasks) { [Fabricate(:running_task, slot: slot)] }

      before do
        allow(RescheduleTasksForMissingRunners).to receive(:new)
          .with(started_tasks: started_tasks, runner_ids: [runner_id])
          .and_return(reschedule_tasks_for_missing_containers_service)
      end

      it "calls RescheduleTasksForMissingRunners perform" do
        expect(reschedule_tasks_for_missing_containers_service).to receive(:perform)
        subject.perform(node: node)
      end
    end

    context "sends metrics" do
      let(:container_state) { "exited" }
      let(:metrics) { double(Metrics) }

      before { allow(Metrics).to receive(:new).with("runners").and_return(metrics) }

      it "sends metrics with running count" do
        expect(metrics).to receive(:count).with(
          hostname: node.hostname,
          runner_type: "docker",
          capacity_reached: false,
          schedule_pending: 0,
          total_runners: 1,
          exited_runners: 1
        )

        subject.perform(node: node)
      end
    end
  end
end
