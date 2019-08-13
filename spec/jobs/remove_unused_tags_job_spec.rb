# frozen_string_literal: true

require 'rails_helper'

RSpec.describe RemoveUnusedTagsJob, type: :job do
  let(:task) { Fabricate(:task, tags: task_tags_hash) }
  let(:perform) { subject.perform }

  before do
    Fabricate(:task_tag, name: "pass", values: ["1", "2"])
    Fabricate(:task_tag, name: "media_type", values: ["video", "audio", "subtitle"])
    Fabricate(:task_tag, name: "slug", values: ["task-slug", "slug4788h", "slug8552h"])
  end

  context "when there are tags not referenced by tasks" do
    before do
      Fabricate(:task, tags: {pass: 1, media_type: "video"})
    end

    it "removes the tag" do
      perform
      expect(TaskTag.where(name: "slug")).to have(0).tags
    end

    it "does not remove existing tags" do
      perform
      expect(TaskTag.where(name: "media_type")).to have(1).tag
    end
  end

  context "when there are values not referenced by tasks" do
    before do
      Fabricate(:task, tags: {pass: "1", media_type: "video"})
    end

    it "removes values not referenced" do
      perform
      values = TaskTag.find_by(name: "media_type").values
      expect(values).to eq(["video"])
    end
  end
end
