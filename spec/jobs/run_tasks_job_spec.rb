require 'rails_helper'

RSpec.describe RunTasksJob, type: :service do
  let(:task) { Fabricate(:task) }
  let!(:slot) { Fabricate(:slot, name: "slot1_1", execution_type: "io") }

  context "when there are tasks to run" do
    before do
      allow(FetchTask).to receive(:have_tasks?).and_return(true, false)
      allow(FetchTask).to receive(:first_pending) { task }
    end

    context "and there is an slot available" do
      before do
        allow_any_instance_of(AllocateSlot).to receive(:slots_available?).and_return(true, false)
        allow_any_instance_of(AllocateSlot).to receive(:first_available).and_return(slot, slot, slot, nil)
      end

      context "and the task aquiring was successful" do
        it "schedule RunTaskJob with slot and task" do
          subject.perform
          expect(RunTaskJob).to have_been_enqueued.with(task: task, slot: slot)
        end

        it "marks task as starting" do
          expect { subject.perform }.to change(task, :status).to("starting")
        end

        context "and the slot aquiring was not successful" do
          before do
            allow_any_instance_of(AllocateSlot).to receive(:call).and_return(nil)
          end

          it "mark task as waiting again" do
            expect { subject.perform }.to_not change(task, :status)
          end
        end
      end

      context "and the task aquiring was not successful" do
        before do
          allow_any_instance_of(FetchTask).to receive(:call).and_return(nil)
        end
        it "does not schedule RunTaskJob" do
          subject.perform
          expect(RunTaskJob).to_not have_been_enqueued
        end

      end
    end

    context "and there is no slots available" do
      before do
        allow_any_instance_of(AllocateSlot).to receive(:slots_available?).and_return(false)
        allow_any_instance_of(AllocateSlot).to receive(:first_available).and_return(nil)
      end

      it "does not schedule RunTaskJob" do
        subject.perform
        expect(RunTaskJob).to_not have_been_enqueued
      end

      it "does not change task status" do
        expect { subject.perform }.to_not change(task, :status)
      end
    end
  end

  context "when there is no task to run" do
    before do
      allow(FetchTask).to receive(:have_tasks?).and_return(false)
    end

    it "does not schedule RunTaskJob with slot and task" do
      subject.perform
      expect(RunTaskJob).to_not have_been_enqueued
    end
  end
end
