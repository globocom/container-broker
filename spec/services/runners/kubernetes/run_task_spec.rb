# frozen_string_literal: true

require "rails_helper"

RSpec.describe Runners::Kubernetes::RunTask do
  let(:task) { Fabricate(:task, name: "Test task #1") }
  let(:node) { Fabricate(:node_kubernetes) }
  let(:slot) { Fabricate(:slot_attaching, node: node) }
  let(:job_name) { "job-name" }
  let(:kubernetes_client) { double(KubernetesClient, create_job: job_name) }

  before do
    allow(node).to receive(:kubernetes_client).and_return(kubernetes_client)
    allow(kubernetes_client).to receive(:create_job).and_return(job_name)
  end

  it "calls create_job in the kubernetes client" do
    expect(kubernetes_client).to receive(:create_job)

    subject.perform(task: task, slot: slot)
  end

  context "creates job with parameters" do
    before { subject.perform(task: task, slot: slot) }

    it "with job_name" do
      expect(kubernetes_client).to have_received(:create_job).with(
        hash_including(
          job_name: a_string_starting_with("test-task-1-")
        )
      )
    end

    it "with image" do
      expect(kubernetes_client).to have_received(:create_job).with(
        hash_including(
          image: task.image
        )
      )
    end

    it "with cmd" do
      expect(kubernetes_client).to have_received(:create_job).with(
        hash_including(
          cmd: task.cmd
        )
      )
    end

    it "with node_selector" do
      expect(kubernetes_client).to have_received(:create_job).with(
        hash_including(
          node_selector: node.kubernetes_config.node_selector
        )
      )
    end

    context "when task has storage mount" do
      it "with internal mounts" do
        expect(kubernetes_client).to have_received(:create_job).with(
          hash_including(
            internal_mounts: [
              {
                name: described_class::NFS_NAME,
                mountPath: task.ingest_storage_mount
              }
            ]
          )
        )
      end

      it "with external mounts" do
        expect(kubernetes_client).to have_received(:create_job).with(
          hash_including(
            external_mounts: [
              {
                name: described_class::NFS_NAME,
                nfs: {
                  server: node.kubernetes_config.nfs_server,
                  path: node.kubernetes_config.nfs_path
                }
              }
            ]
          )
        )
      end
    end

    context "when task does not have storage mount" do
      let(:task) { Fabricate(:task, ingest_storage_mount: nil) }

      it "without internal mounts" do
        expect(kubernetes_client).to have_received(:create_job)
          .with(hash_including(internal_mounts: []))
      end

      it "without external mounts" do
        expect(kubernetes_client).to have_received(:create_job)
          .with(hash_including(external_mounts: []))
      end
    end
  end

  context "when the creation fails" do
    context "and is a node connectivity problem" do
      before do
        allow(kubernetes_client).to receive(:create_job).and_raise(SocketError, "Error connecting with kubernetes")
      end

      it "raises NodeConnectionError" do
        expect { subject.perform(task: task, slot: slot) }.to raise_error(Node::NodeConnectionError, "SocketError: Error connecting with kubernetes")
      end
    end

    context "and is other error" do
      before do
        allow(kubernetes_client).to receive(:create_job).and_raise(StandardError, "Error parsing the task command")
      end

      it "raises the same error" do
        expect { subject.perform(task: task, slot: slot) }.to raise_error(StandardError, "Error parsing the task command")
      end
    end
  end

  context "when task starts without errors" do
    it "returns job name" do
      expect(subject.perform(task: task, slot: slot)).to start_with(job_name)
    end
  end
end
