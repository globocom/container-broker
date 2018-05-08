require 'rails_helper'

RSpec.describe RunTaskJob, type: :job do

  let(:node) { Node.create!(hostname: "docker.test") }
  let(:task) { Task.create!(name: "task-name", image: "#{image}:#{image_tag}", cmd: "-i input.txt -metadata comment='Encoded by Globo.com' output.mp4", storage_mount: "/tmp/workdir") }
  let(:slot) { Slot.create!(node: node, status: "attaching") }
  let(:image) { "busybox" }
  let(:image_tag) { "3.1" }

  let(:perform) { subject.perform(task: task, slot: slot) }
  let(:container) { double("Docker::Container", id: "11223344") }

  before do
    allow(Docker::Image).to receive(:create)
    allow(Docker::Container).to receive(:create) { container }
    allow(container).to receive(:start)
  end

  shared_examples "releases slot and retry the task" do
    it "releases the slot" do
      perform
      expect(slot).to be_idle
    end

    it "marks task to retry" do
      perform
      expect(task).to be_retry
    end

    it "increments retry count" do
      expect{perform}.to change(task, :try_count).by(1)
    end

  end

  context "when node is unavailable" do
    before do
      allow(Docker::Image).to receive(:create).and_raise(Excon::Error, "Error connecting to docker")
    end

    it "mark node as unavailable" do
      perform
      expect(node).to_not be_available
    end

    include_examples "releases slot and retry the task"

    context "sets task error message" do
      context "standard errors" do
        it "sets simple error message" do
          expect{perform}.to change(task, :error).to("Docker connection error: Error connecting to docker")
        end
      end

      context "errors with response bodies" do
        before do
          allow(Docker::Image).to receive(:create).and_raise(Excon::Error::HTTPStatus.new("Error connecting to docker", nil, double(body: "Error details")))
        end

        it "sets message with error details from response body" do
          expect{perform}.to change(task, :error).to("Docker connection error: Error connecting to docker\nError details")
        end
      end
    end
  end

  context "when docker image does not exists" do
    before do
      allow(Docker::Image).to receive(:create).and_raise(Docker::Error::NotFoundError)
    end
    include_examples "releases slot and retry the task"
    it "sets task error message" do
      expect{perform}.to change(task, :error).to("Docker image not found: Docker::Error::NotFoundError")
    end
  end

  context "when node is available and image exists" do
    before do

    end

    let(:container_create_options) do
      {
        "Image" => "#{image}:#{image_tag}",
        "HostConfig" => {
          "Binds" => ["/tmp/ef-shared:/tmp/workdir"],
          "LogConfig" =>  {
            "Type" => "fluentd",
            "Config" => {
              "tag" => "docker.{{.ID}}",
              "fluentd-sub-second-precision" => "true"
            }
          }
        },
        "Cmd" => ["-i", "input.txt", "-metadata", "comment='Encoded by Globo.com'", "output.mp4"]
      }
    end

    it "creates the image" do
      expect(Docker::Image).to receive(:create).with({"fromImage" => image, "tag" => image_tag}, nil, kind_of(Docker::Connection))

      perform
    end

    it "creates the container" do
      expect(Docker::Container).to receive(:create).with(container_create_options, kind_of(Docker::Connection))

      perform
    end

    it "starts the container" do
      expect(container).to receive(:start)

      perform
    end

    it "updates task container_id" do
      expect{perform}.to change(task, :container_id).to(container.id)
    end

    it "updates task status" do
      expect{perform}.to change(task, :status).to("started")
    end

    it "updates task slot" do
      expect{perform}.to change(task, :slot).to(slot)
    end

    it "updates slot status to running" do
      expect{perform}.to change(slot, :status).to("running")
    end

    it "updates slot current task" do
      expect{perform}.to change(slot, :current_task).to(task)
    end

    it "updates slot container_id" do
      expect{perform}.to change(slot, :container_id).to(container.id)
    end

    it "calls node update_usage" do
      expect(node).to receive(:update_usage)
      perform
    end
  end
end
