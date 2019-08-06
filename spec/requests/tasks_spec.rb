require 'rails_helper'

RSpec.describe "Tasks", type: :request do
  describe "POST /tasks" do
    let(:perform) { post "/tasks", params: data }
    let(:task_name) { "test task" }
    let(:task_image) { "busybox:1.25" }
    let(:task_cmd) { "sleep 5" }
    let(:task_storage_mount) { "/var/log" }
    let(:task_execution_type) { "test" }
    let(:task_tags) do
      {
        "api_id" => "123456",
        "media_id" => "6c4cf8d6-36a3-4c0d-8799-0ae79fffa9ce",
        "slug" => "tag1",
      }
    end

    let(:data) do
      {
        task: {
          name: task_name,
          image: task_image,
          cmd: task_cmd,
          storage_mount: task_storage_mount,
          tags: task_tags,
          execution_type: task_execution_type,
        }
      }
    end

    context "with valid data" do
      it "respond with HTTP 200" do
        perform
        expect(response).to be_success
      end

      it "creates a task" do
        expect{perform}.to change(Task, :count).by(1)
      end

      it "with valid parameters" do
        perform
        expect(Task.last).to have_attributes(
          name: task_name,
          image: task_image,
          cmd: task_cmd,
          storage_mount: task_storage_mount,
          tags: task_tags)
      end
    end

    context "with invalid data" do
      let(:data) {
        {
          task: {
            name: ""
          }
        }
      }

      it "responds with " do
        perform
        expect(response).to be_unprocessable
      end
    end
  end

  describe "GET /tasks/:id" do
    let(:task) { Fabricate(:task) }
    let(:perform) { get "/tasks/#{task.uuid}"}

    it "returns the task" do
      perform
      expect(JSON.parse(response.body)).to match({
        "uuid" => task.uuid,
        "created_at" => task.created_at.iso8601(3),
        "error" => task.error,
        "exit_code" => task.exit_code,
        "finished_at" => task.finished_at.iso8601(3),
        "progress" => task.progress,
        "seconds_running" => task.seconds_running,
        "started_at" => task.started_at.iso8601(3),
        "status" => task.status,
        "execution_type" => task.execution_type,
        "try_count" => task.try_count,
      })
    end

    it "responds with success" do
      perform
      expect(response).to be_success
    end
  end

  describe "DELETE /tasks/failed" do
    let(:perform) { delete "/tasks/failed"}
    let!(:task1) { Fabricate(:task) }
    let!(:task2) { Fabricate(:task, status: "error") }
    let!(:task3) { Fabricate(:task, status: "error") }

    describe "with error tasks" do
      it "clears all failed tasks" do
        perform

        expect(Task.find(task1)).to match(task1)
        expect(Task.find(task2)).to be_nil
        expect(Task.find(task3)).to be_nil

        expect(response).to be_success
      end
    end
  end

  describe "GET /tasks/healthcheck" do
    let(:task) { Fabricate(:task) }
    let(:perform) { get "/tasks/healthcheck"}

    describe "with all tasks succeeding" do
      it "gets working status" do
        perform
        expect(JSON.parse(response.body)).to match({
          "status" => "WORKING",
          "failed_tasks" => [],
        })
      end
    end

    describe "with invalid tasks" do
      let!(:slot) { Fabricate(:slot) }
      let!(:task) { Fabricate(:task, slot: slot, status: "error") }

      it "gets failing status" do
        perform
        expect(JSON.parse(response.body)).to match({
          "status" => "FAILING",
          "failed_tasks" => [
            hash_including("uuid" => task.uuid)
          ],
        })
      end
    end
  end
end
