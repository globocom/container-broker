# frozen_string_literal: true

require "rails_helper"

RSpec.describe ReleaseSlotJob, type: :job do
  let(:container_id) { "11223344" }
  let(:node) { Fabricate(:node) }
  let(:slot) { Fabricate(:slot_releasing, node: node, current_task: task, container_id: container_id, execution_type: "test") }
  let(:task) { Fabricate(:task) }
  let(:check_for_slot_removal_service) { double("CheckForSlotRemoval") }
  let(:slot_removed) { "<defined-in-each-context>" }

  before do
    allow_any_instance_of(UpdateTaskStatusJob).to receive(:perform)

    allow(CheckForSlotRemoval).to receive(:new)
      .with(slot: slot)
      .and_return(check_for_slot_removal_service)
    allow(check_for_slot_removal_service).to receive(:perform)
    allow(check_for_slot_removal_service).to receive(:removed?).and_return(slot_removed)
  end

  it "updates task status" do
    expect(UpdateTaskStatusJob).to receive(:perform_now).with(task)
    subject.perform(slot: slot)
  end

  it "schedules container removal from docker" do
    subject.perform(slot: slot)
    expect(RemoveContainerJob).to have_been_enqueued.with(node: slot.node, container_id: container_id)
  end

  context "when update task status raises and error" do
    before do
      allow(UpdateTaskStatusJob).to receive(:perform_now).and_raise(Excon::Error)
    end

    it "raises the error" do
      expect { subject.perform(slot: slot) }.to raise_error(Excon::Error)
    end

    it "does not release the slot" do
      expect do
        begin
          subject.perform(slot: slot)
        rescue StandardError
          nil
        end
        slot.reload
      end.to_not change(slot, :status)
    end
  end

  context "when slot doesn't need to be removed" do
    let(:slot_removed) { false }

    it "releases the slot" do
      expect { subject.perform(slot: slot) }.to change(slot, :status).to("idle")
    end

    it "enqueues new tasks" do
      subject.perform(slot: slot)
      expect(RunTasksJob).to have_been_enqueued.at_least(1).times
    end
  end

  context "when slot needs to be removed" do
    let(:slot_removed) { true }

    it "doesn't change the status" do
      expect { subject.perform(slot: slot) }.to_not change(slot, :status)
    end

    it "doesn't enqueue new tasks" do
      subject.perform(slot: slot)
      expect { subject.perform(slot: slot) }.to_not have_enqueued_job(RunTasksJob)
    end
  end
end
