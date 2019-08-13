# frozen_string_literal: true

require 'rails_helper'

RSpec.describe MonitorUnresponsiveNodeJob, type: :job do
  context "when node is unavailable" do
    let(:node) { Fabricate(:node, status: "unavailable", last_error: "connection error") }

    context "and it becomes available" do
      before { allow(Docker).to receive(:info) { "ok" } }

      it "marks node available again" do
        expect { subject.perform(node: node) }.to change(node, :status).to("available")
      end

      it "tries to run new tasks" do
        subject.perform(node: node)
        expect(RunTasksForAllExecutionTypesJob).to have_been_enqueued
      end

      it "clears last error" do
        expect { subject.perform(node: node) }.to change(node, :last_error).to(nil)
      end
    end

    context "when node still unavailable" do
      before { allow(Docker).to receive(:info).and_raise("error getting docker info") }

      it "marks node as unavailable" do
        expect { subject.perform(node: node) }.to_not change(node, :available?)
      end

      it "sets last error" do
        expect { subject.perform(node: node) }.to change(node, :last_error).to("error getting docker info")
      end
    end
  end

  context "when node is unstable" do
    let(:node) { Fabricate(:node, status: "unstable", last_error: "connection error") }

    context "and it becomes available" do
      before { allow(Docker).to receive(:info) { "ok" } }

      it "marks node available again" do
        expect { subject.perform(node: node) }.to change(node, :status).to("available")
      end

      it "tries to run new tasks" do
        subject.perform(node: node)
        expect(RunTasksForAllExecutionTypesJob).to have_been_enqueued
      end

      it "clears last error" do
        expect { subject.perform(node: node) }.to change(node, :last_error).to(nil)
      end
    end

    context "when node still unavailable" do
      before { allow(Docker).to receive(:info).and_raise("error getting docker info") }

      it "marks node as unavailable" do
        expect { subject.perform(node: node) }.to_not change(node, :available?)
      end

      it "sets last error" do
        expect { subject.perform(node: node) }.to change(node, :last_error).to("error getting docker info")
      end
    end
  end
end
