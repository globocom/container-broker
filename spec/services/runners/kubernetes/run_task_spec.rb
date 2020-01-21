# frozen_string_literal: true

require "rails_helper"

RSpec.describe Runners::Kubernetes::RunTask do
  let(:task) { Fabricate(:task) }
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
          job_name: a_string_starting_with(task.name)
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

      it "with external mounts" do
        expect(kubernetes_client).to have_received(:create_job)
          .with(hash_including(external_mounts: []))
      end
    end
  end

  context "when task starts without errors" do
    it "updates the task with the job name" do
      expect { subject.perform(task: task, slot: slot) }
        .to change { task.reload.container_id }
        .to(job_name)
    end

    it "marks task as started" do
      subject.perform(task: task, slot: slot)

      expect(task.reload).to be_started
    end

    it "changes slot status to running" do
      subject.perform(task: task, slot: slot)

      expect(slot.reload).to be_running
    end

    it "sets slot current task" do
      subject.perform(task: task, slot: slot)

      expect(slot.reload.current_task).to eq(task)
    end

    it "sets slot container_id with job_name" do
      subject.perform(task: task, slot: slot)

      expect(slot.reload.container_id).to eq(job_name)
    end

    it "sends metrics to measures" do
      metrics = double(Metrics)
      expect(Metrics).to receive(:new).with("tasks").and_return(metrics)
      expect(metrics).to receive(:count).with(hash_including(task_id: task.id))

      subject.perform(task: task, slot: slot)
    end
  end

  context "when there is an error in job creation" do
    before do
      allow(kubernetes_client).to receive(:create_job).and_raise(SocketError, "Error creating job in kubernetes cluster")
    end

    it "does not raises the error" do
      expect { subject.perform(task: task, slot: slot) }.to_not raise_error
    end

    it "marks task as retry" do
      subject.perform(task: task, slot: slot)
      expect(task.reload).to be_retry
    end

    it "sets the error in the task" do
      subject.perform(task: task, slot: slot)
      expect(task.error).to eq("SocketError: Error creating job in kubernetes cluster")
    end

    it "releases the slot" do
      subject.perform(task: task, slot: slot)
      expect(slot.reload).to be_idle
    end
  end
end
