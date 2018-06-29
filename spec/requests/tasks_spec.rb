require 'rails_helper'

RSpec.describe "Tasks", type: :request do
  describe "POST /tasks" do
    let(:perform) { post "/tasks", params: data }
    let(:task_name) { "test task" }
    let(:task_image) { "busybox:1.25" }
    let(:task_cmd) { "sleep 5" }
    let(:task_storage_mount) { "/var/log" }
    let(:data) do
      {
        task: {
          name: task_name,
          image: task_image,
          cmd: task_cmd,
          storage_mount: task_storage_mount,
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
        expect(Task.last).to have_attributes(name: task_name, image: task_image, cmd: task_cmd, storage_mount: task_storage_mount)
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
        "name" => task.name,
        "created_at" => task.created_at.iso8601(3),
        "error" => task.error,
        "exit_code" => task.exit_code,
        "finished_at" => task.finished_at.iso8601(3),
        "progress" => task.progress,
        "seconds_running" => task.seconds_running,
        "started_at" => task.started_at.iso8601(3),
        "status" => task.status,
        "try_count" => task.try_count,
      })
    end

    it "responds with success" do
      perform
      expect(response).to be_success
    end
  end
end
