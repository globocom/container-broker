require 'rails_helper'

RSpec.describe RunTasksJob, type: :service do
  let(:task) {
    Task.create!
  }
  let(:slot) { Node.create!(cores: 2).tap(&:populate).slots.first }

  before do
    # allow(LockManager).to receive(:lock).and_yield
  end

  context "when there is task to run" do
    before do
      allow(FetchTask).to receive(:have_tasks?).and_return(true, false)
      allow(FetchTask).to receive(:first_pending) { task }
      allow(AllocateSlot).to receive(:slots_available?).and_return(true, false)
      allow(AllocateSlot).to receive(:first_available).and_return(slot, slot, slot, nil)
    end

    context "and there is an slot available" do
      it "schedule RunTaskJob with slot and task" do
        subject.perform
        expect(RunTaskJob).to have_been_enqueued.with(task: task, slot: slot)
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
