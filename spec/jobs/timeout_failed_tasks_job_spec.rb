# frozen_string_literal: true

require "rails_helper"

RSpec.describe TimeoutFailedTasksJob, type: :job do
  let(:task) { Fabricate(:task, status: "failed", finished_at: finished_at) }
  let(:finished_at) { "Defined in each context" }
  let(:now_time) { "Thu, 05 Dec 2019 23:59:00 +0000 " }
  let(:perform) { subject.perform }

  before do
    allow(Task).to receive(:where).and_return(task)
  end

  context "when task failed less than 20 hours ago" do
    let(:finished_at) { "Thu, 05 Dec 2019 23:50:00 +0000" }

    it "keeps task as failed" do
      perform
      expect(task.status).to be("failed")
    end
  end

  context "when task failed more than 20 hours ago" do
    let(:finished_at) { "Thu, 03 Dec 2019 23:50:00 +0000" }

    it "marks the task as error" do
      perform
      expect(task.status).to be("error")
    end
  end
end
