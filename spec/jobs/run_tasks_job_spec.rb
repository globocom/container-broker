# frozen_string_literal: true

require "rails_helper"

RSpec.describe RunTasksJob, type: :service do
  let(:execution_type) { "cpu" }
  let!(:task) { Fabricate(:task, execution_type: execution_type) }
  let!(:slot) { Fabricate(:slot_idle, execution_type: execution_type) }

  context "when job is locked" do
    let(:lock_manager_job) { double(LockManager) }

    before do
      allow(LockManager).to receive(:new)
        .with(type: described_class, id: execution_type, expire: 1.minute, wait: false)
        .and_return(lock_manager_job)
      allow(lock_manager_job).to receive(:lock).and_return(false)

      allow(described_class).to receive(:set).with(wait: 10.seconds).and_return(described_class)
    end

    it "reschedules the job" do
      expect(described_class).to receive(:perform_later).with(execution_type: execution_type)

      subject.perform(execution_type: execution_type)
    end
  end

  context "when job is unlocked" do
    context "with no available nodes" do
      before do
        allow(Node).to receive(:available).and_return([])
      end

      it "does not fetch pending tasks" do
        expect_any_instance_of(LockTask).to_not receive(:call)

        subject.perform(execution_type: execution_type)
      end
    end

    context "with available nodes" do
      let(:fetch_task_service) { double("LockTask") }

      context "and no pending tasks" do
        before do
          allow(LockTask).to receive(:new).with(execution_type: execution_type).and_return(fetch_task_service)
          allow(fetch_task_service).to receive(:call).and_return(nil)
          allow(fetch_task_service).to receive(:first_pending).and_return(nil)
        end

        it "does not check the slots" do
          expect(LockSlot).not_to receive(:new)

          subject.perform(execution_type: execution_type)
        end
      end

      context "and pending tasks" do
        before do
          allow(fetch_task_service).to receive(:first_pending).and_return(task)
        end

        context "and no available slots for execution type" do
          before do
            allow_any_instance_of(LockSlot).to receive(:perform).and_return(nil)
          end

          it "does not run task job" do
            expect(RunTaskJob).to_not have_been_enqueued

            subject.perform(execution_type: execution_type)
          end
        end

        context "and available slots for execution_type" do
          it "creates run task job" do
            subject.perform(execution_type: execution_type)
            expect(RunTaskJob).to have_been_enqueued.with(task: task, slot: slot)
          end
        end
      end
    end
  end
end
