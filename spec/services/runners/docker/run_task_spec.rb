# frozen_string_literal: true

require "rails_helper"

RSpec.describe Runners::Docker::RunTask, type: :service do
  let(:node) { Fabricate(:node) }
  let(:runner_id) { "task-nametask-nametask-nametask-name-xf9865g" }
  let(:task) do
    Task.create!(
      name: "task-name",
      image: "#{image}:#{image_tag}",
      cmd: "-i input.txt -metadata comment='Encoded by Globo.com' output.mp4",
      storage_mount: "/tmp/workdir",
      ingest_storage_mount: "/ingest",
      execution_type: "test"
    )
  end

  let(:slot) { Fabricate(:slot_attaching, node: node, execution_type: "test") }
  let(:image) { "busybox" }
  let(:image_tag) { "3.1" }

  let(:perform) { subject.perform(task: task, slot: slot, runner_id: runner_id) }
  let(:container) { double("Docker::Container", id: "11223344") }

  before do
    allow(Docker::Image).to receive(:create)
    allow(Docker::Container).to receive(:create) { container }
    allow(Docker::Image).to receive(:exist?)
    allow(container).to receive(:start)
  end

  context "when node is unavailable" do
    before do
      allow(Docker::Image).to receive(:create).and_raise(Excon::Error, "Error connecting to docker")
    end

    context "with standard errors" do
      it "raises just error message" do
        expect { perform }.to raise_error(Node::NodeConnectionError)
      end
    end

    context "errors with response bodies" do
      before do
        allow(Docker::Image).to receive(:create).and_raise(Excon::Error::HTTPStatus.new("Error connecting to docker", nil, double(body: "Error details")))
      end

      it "raises the error message with the response body" do
        expect { perform }.to raise_error("Docker connection error: Error connecting to docker\nError details")
      end
    end
  end

  context "when docker image does not exists in registry" do
    before do
      allow(Docker::Image).to receive(:create).and_raise(Docker::Error::NotFoundError)
    end

    it "sets task error message" do
      expect { perform }.to raise_error("Docker image not found: Docker::Error::NotFoundError")
    end
  end

  context "when docker image does not exists locally in machine" do
    before do
      allow(Docker::Image).to receive(:exist?).with(task.image, hash, a_kind_of(Docker::Connection)).and_return(false)
    end

    it "creates image in machine" do
      expect(Docker::Image).to receive(:create).with({ "fromImage" => image, "tag" => image_tag }, nil, a_kind_of(Docker::Connection))
      perform
    end
  end

  context "when node is available and image exists" do
    let(:container_create_options) do
      {
        "Image" => "#{image}:#{image_tag}",
        "Name" => runner_id,
        "HostConfig" => {
          "Binds" => [
            "/tmp/ef-shared:/tmp/workdir",
            "/opt/ef-shared:/ingest"
          ],
          "NetworkMode" => ""
        },
        "Entrypoint" => [],
        "Cmd" => ["sh", "-c", "-i input.txt -metadata comment='Encoded by Globo.com' output.mp4"]
      }
    end

    context "and image exists locally in machine" do
      before do
        allow(Docker::Image).to receive(:exist?).with(task.image, kind_of(Hash), a_kind_of(Docker::Connection)).and_return(true)
      end

      it "does not call image create" do
        expect(Docker::Image).to_not receive(:create)
        perform
      end
    end

    context "and command is invalid" do
      before do
        allow(container).to receive(:start).and_raise(Docker::Error::ClientError, "executable file not found")
      end

      it "raises an error with the message" do
        expect { perform }.to raise_error("executable file not found")
      end
    end

    it "creates the image" do
      expect(Docker::Image).to receive(:create).with({ "fromImage" => image, "tag" => image_tag }, nil, kind_of(Docker::Connection))

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

    it "returns the runner_id" do
      expect(perform).to eq(runner_id)
    end
  end
end
