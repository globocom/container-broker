# frozen_string_literal: true

require "rails_helper"

RSpec.describe TimeoutFailedTasksJob, type: :job do
  let(:perform) { subject.perform }

  context "when task failed less than 20 hours ago" do
    let!(:task) { Fabricate(:task, status: "failed", finished_at: finished_at) }
    let(:finished_at) { Time.current }

    it "keeps task as failed" do
      perform

      expect(task).to be_failed
    end
  end

  context "when task failed more than 20 hours ago" do
    let!(:task) { Fabricate(:task, status: "failed", finished_at: finished_at) }
    let(:finished_at) { "Thu, 03 Dec 2019 23:50:00 +0000" }

    it "marks the task as error" do
      expect do
        perform
        task.reload
      end.to change(task, :status)
        .from("failed")
        .to("error")
    end

    context "and task does not have logs" do
      it "logs the timeout on task" do
        perform

        task.reload

        expect(task.get_logs).to eq("\nThis task was automatically marked as error due to timeout.\n")
      end
    end

    context "and task has logs already" do
      it "concats logs all together" do
        task.set_logs("previous log ".dup)

        task.save!

        perform

        task.reload

        expect(task.get_logs).to eq("previous log \nThis task was automatically marked as error due to timeout.\n")
      end
    end
  end
end
