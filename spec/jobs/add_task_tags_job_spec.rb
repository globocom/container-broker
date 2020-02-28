# frozen_string_literal: true

require "rails_helper"

RSpec.describe AddTaskTagsJob, type: :job do
  let(:task) { Fabricate(:task, tags: task_tags_hash) }
  let(:perform) { subject.perform(task: task) }

  before do
    Fabricate(:task_tag, name: "pass", values: %w[1 2])
    Fabricate(:task_tag, name: "media_type", values: %w[video audio])
    Fabricate(:task_tag, name: "slug", values: ["task-slug"])
  end

  context "when tag already exist" do
    let(:task_tags_hash) do
      {
        slug: "task-slug",
        pass: "1"
      }
    end

    it "does not create new tags" do
      expect { perform }.to_not change(TaskTag, :count)
    end
  end

  context "when tag does not exist" do
    let(:task_tags_hash) do
      {
        api_id: "123456"
      }
    end

    it "create new task tag" do
      perform
      expect(TaskTag.where(name: "api_id")).to_not be_empty
    end
  end
end
