# frozen_string_literal: true

require "rails_helper"

RSpec.describe MonitorUnresponsiveNodeJob, type: :job do
  let(:node) { Fabricate(:node) }
  let(:docker_node_availability_instance) { double(Runners::Docker::NodeAvailability) }

  before do
    allow(node).to receive(:runner_service)
      .with(:node_availability)
      .and_return(docker_node_availability_instance)
  end

  context "when node is unavailable" do
    let(:node) { Fabricate(:node, status: "unavailable", last_error: "connection error") }

    context "and it becomes available" do
      before do
        allow(docker_node_availability_instance).to receive(:perform).and_return("ok")
      end

      it "marks node available again" do
        expect { subject.perform(node: node) }.to change(node, :status).to("available")
      end

      it "tries to run new tasks" do
        subject.perform(node: node)
        expect(RunTasksForAllExecutionTypesJob).to have_been_enqueued
      end
    end

    context "when node still unavailable" do
      before { allow(docker_node_availability_instance).to receive(:perform).and_raise("error getting docker info") }

      it "marks node as unavailable" do
        expect { subject.perform(node: node) }.to_not change(node, :available?)
      end

      it "sets last error" do
        expect { subject.perform(node: node) }.to change(node, :last_error).to("RuntimeError: error getting docker info")
      end
    end
  end

  context "when node is unstable" do
    let(:node) { Fabricate(:node, status: "unstable", last_error: "connection error") }

    context "and it becomes available" do
      before { allow(docker_node_availability_instance).to receive(:perform).and_return("ok") }

      it "marks node av ailable again" do
        expect { subject.perform(node: node) }.to change(node, :status).to("available")
      end

      it "tries to run new tasks" do
        subject.perform(node: node)
        expect(RunTasksForAllExecutionTypesJob).to have_been_enqueued
      end
    end

    context "when node still unavailable" do
      before { allow(docker_node_availability_instance).to receive(:perform).and_raise("error getting docker info") }

      it "marks node as unavailable" do
        expect { subject.perform(node: node) }.to_not change(node, :available?)
      end

      it "sets last error" do
        expect { subject.perform(node: node) }.to change(node, :last_error).to("RuntimeError: error getting docker info")
      end
    end
  end
end
