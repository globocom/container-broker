# frozen_string_literal: true

require "rails_helper"

RSpec.describe "Status", type: :request do
  describe "GET /status/tasks" do
    before { stub_const("#{StatusController}::LIMIT_TASKS", 5) }

    context "without parameters" do
      before { Fabricate.times(10, :task) }

      it "returns a fixed number of tasks" do
        get "/status/tasks"

        expect(json_response).to have(5).tasks
      end
    end

    context "with limit" do
      before { Fabricate.times(10, :task) }

      it "returns only the requested count limit" do
        get "/status/tasks?limit=3"

        expect(json_response).to have(3).tasks
      end
    end

    context "with tag filter" do
      before do
        Fabricate(:task, name: "task-video-a", tags: { type: "video", code: "a" })
        Fabricate(:task, name: "task-video-b", tags: { type: "video", code: "b" })
        Fabricate(:task, name: "task-audio-c", tags: { type: "audio", code: "c" })
      end

      it "returns just tasks that matches with all filters" do
        get "/status/tasks?tags[type]=video&tags[code]=b"

        expect(json_response).to contain_exactly(
          include("name" => "task-video-b")
        )
      end

      it "returns just tasks that matches with any tag filtered" do
        get "/status/tasks?tags[type]=video"

        expect(json_response).to contain_exactly(
          include("name" => "task-video-a"),
          include("name" => "task-video-b")
        )
      end
    end

    context "with status filter" do
      before do
        Fabricate.times(5, :task, status: "waiting")
        Fabricate(:task, name: "task-started", status: "started")
      end

      it "returns just tasks that matches the status filter" do
        get "/status/tasks?status=started"

        expect(json_response).to contain_exactly(
          include("name" => "task-started")
        )
      end
    end

    it "responds with success" do
      get "/status/tasks"

      expect(response).to be_successful
    end
  end
end
