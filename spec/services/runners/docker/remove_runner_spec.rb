# frozen_string_literal: true

require "rails_helper"

RSpec.describe Runners::Docker::RemoveRunner, type: :service do
  let(:node) { Node.create(hostname: "local.test") }
  let(:runner_id) { "11223344" }
  let(:container) { double("Docker::Container", info: container_info) }
  let(:container_info) { { "State" => { "Status" => container_state } } }
  let(:container_state) { "<to be defined>" }
  let(:docker_connection) { double("Docker::Connection") }

  let(:perform) do
    subject.perform(node: node, runner_id: runner_id)
  end

  before do
    allow(node).to receive(:docker_connection).and_return(docker_connection)
    allow(Docker::Container).to receive(:get).with(runner_id, { all: true }, docker_connection) do
      container
    end
    allow(container).to receive(:delete)
    allow(container).to receive(:kill)
  end

  context "when container is running" do
    let(:container_state) { "running" }
    it "calls kill on container" do
      expect(container).to receive(:kill)
      perform
    end

    it "calls delete on container" do
      expect(container).to receive(:delete)
      perform
    end
  end

  context "when container is not running" do
    let(:container_state) { "exited" }
    it "does not call kill on container" do
      expect(container).to_not receive(:kill)
      perform
    end

    it "calls delete on container" do
      expect(container).to receive(:delete)
      perform
    end
  end
end
