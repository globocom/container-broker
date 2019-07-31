require 'rails_helper'

RSpec.describe RunTasksJob, type: :service do
  let!(:task) { Fabricate(:task, execution_type: "cpu") }

  let!(:slot) { Fabricate(:slot_idle, execution_type: "cpu") }

  context "with no available nodes" do
    before do
      allow(Node).to receive(:available).and_return([])
    end

    it "does not check the tasks" do
      expect_any_instance_of(FetchTask).to_not receive(:call)

      subject.perform
    end
  end

  context "with available nodes" do
    let(:fetch_task_service) { double("FetchTask") }
    context "and no pending tasks" do
      before do
        allow(FetchTask).to receive(:new).with(execution_types: %w[cpu]).and_return(fetch_task_service)
        allow(fetch_task_service).to receive(:call).and_return(nil)
      end

      it "does not check the slots" do
        expect(AllocateSlot).not_to receive(:new)

        subject.perform
      end
    end

    context "and pending tasks" do
      context "and no available slots for execution type" do
        before do
          allow_any_instance_of(AllocateSlot).to receive(:call).and_return(nil)
        end

        it "does not run task job" do
          expect(RunTaskJob).to_not have_been_enqueued

          subject.perform
        end
      end

      context "and available slots for execution_type" do
        it "creates run task job" do
          subject.perform

          expect(RunTaskJob).to have_been_enqueued.with(task: task, slot: slot)
        end
      end
    end
  end
end
