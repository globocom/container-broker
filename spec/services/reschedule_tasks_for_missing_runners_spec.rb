# frozen_string_literal: true

require "rails_helper"

RSpec.describe RescheduleTasksForMissingRunners, type: :service do
  let(:runner_id) { "123" }
  let(:node) { Fabricate(:node, name: "node-0") }
  let(:slot) { Fabricate(:slot_running, runner_id: runner_id, name: "slot-0", node: node) }
  let!(:started_task) { Fabricate(:running_task, runner_id: runner_id, slot: slot) }

  context "when container exists" do
    let(:runner_ids) { [runner_id] }

    it "does not change task status" do
      expect do
        described_class.new(started_tasks: [started_task], runner_ids: runner_ids).perform
      end.to_not change(started_task, :status)
    end

    it "does not change slot status" do
      expect do
        described_class.new(started_tasks: [started_task], runner_ids: runner_ids).perform
      end.to_not change(slot, :status)
    end
  end

  context "when container does not exist" do
    let(:runner_ids) { ["other_id"] }

    it "changes status to retry" do
      expect do
        described_class.new(started_tasks: [started_task], runner_ids: runner_ids).perform
        started_task.reload
      end.to change(started_task, :status).to("retry")
    end

    it "releases slot" do
      expect do
        described_class.new(started_tasks: [started_task], runner_ids: runner_ids).perform
        slot.reload
      end.to change(slot, :status).to("idle")
    end

    context "and sentry is enabled" do
      before do
        Settings.sentry.enabled = true
      end

      it "sends an event" do
        expect(Raven).to receive(:capture_exception).with(
          "Task retryied because runner #{runner_id} is missing (#{started_task} #{slot})",
          extra: {
            runner: node.runner,
            runner_id: runner_id,
            slot: {
              id: slot.id,
              name: slot.name,
              status: slot.status,
              runner_id: slot.runner_id
            },
            node: {
              id: node.id,
              name: node.name,
              status: node.status
            },
            task: {
              id: started_task.id,
              name: started_task.name,
              status: started_task.status
            }
          }
        )

        described_class.new(started_tasks: [started_task], runner_ids: runner_ids).perform
      end
    end
  end
end
