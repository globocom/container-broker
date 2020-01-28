# frozen_string_literal: true

require "rails_helper"

RSpec.describe Runners::Kubernetes::UpdateNodeStatus, type: :service do
  let(:node) { Fabricate(:node_kubernetes, runner_capacity_reached: nil) }
  let(:slot_status) { :running }
  let(:task) { Fabricate(:task) }
  let!(:slot) { Fabricate(:slot, status: slot_status, runner_id: "job_name", node: node, current_task: task) }
  let(:kubernetes_client) { double(KubernetesClient) }
  let(:pod_job_name) { "job_name" }
  let(:state) do
    {
      running: {
        startedAt: "2020-01-21T21:20:32Z"
      }
    }
  end
  let(:pods) do
    {
      pod_job_name => Kubeclient::Resource.new(
        metadata: {
          labels: {
            "job-name" => pod_job_name
          }
        },
        status: {
          containerStatuses: [
            {
              state: state
            }
          ]
        }
      )
    }
  end

  before do
    allow(node).to receive(:kubernetes_client).and_return(kubernetes_client)
    allow(kubernetes_client).to receive(:fetch_pods).and_return(pods)
  end

  it "updates node last success" do
    expect(node).to receive(:update_last_success)

    subject.perform(node: node)
  end

  it "mark node as capacity unreached" do
    expect { subject.perform(node: node) }.to change(node, :runner_capacity_reached).to(false)
  end

  context "when Kubeclient raises an HTTP error" do
    before do
      allow(kubernetes_client).to receive(:fetch_pods).and_raise(Kubeclient::HttpError.new(nil, "error_message", nil))
    end

    it "registers error" do
      expect(node).to receive(:register_error).with("error_message")

      subject.perform(node: node)
    end
  end

  context "when SocketError is raised" do
    before do
      allow(kubernetes_client).to receive(:fetch_pods).and_raise(SocketError.new("error_message_socket"))
    end

    it "registers error" do
      expect(node).to receive(:register_error).with("error_message_socket")

      subject.perform(node: node)
    end
  end

  context "when slot exists" do
    context "when job is not completed" do
      let(:state) do
        {
          running: {
            startedAt: "2020-01-21T21:20:32Z"
          }
        }
      end

      it "does not release slot" do
        expect(ReleaseSlotJob).not_to receive(:perform_later)
          .with(hash_including(runner_id: "job_name"))

        subject.perform(node: node)
      end
    end

    context "when job is succeeded" do
      let(:state) do
        {
          terminated: {
            exitCode: 0,
            reason: "Completed",
            startedAt: "2020-01-21T21:20:32Z",
            finishedAt: "2020-01-21T21:20:32Z"
          }
        }
      end

      context "and slot is running" do
        it "releases slot" do
          expect { subject.perform(node: node) }.to change { slot.reload.status }.from("running").to("releasing")
        end

        it "performs ReleaseSlotJob" do
          expect(ReleaseSlotJob).to receive(:perform_later)
            .with(hash_including(runner_id: "job_name"))

          subject.perform(node: node)
        end
      end

      context "and slot is not running" do
        let(:slot_status) { :idle }

        it "does not release slot" do
          expect { subject.perform(node: node) }.to_not(change { slot.reload.status })
        end
      end
    end

    context "when job is failed" do
      let(:state) do
        {
          terminated: {
            exitCode: 127,
            reason: "Error",
            startedAt: "2020-01-21T21:20:32Z",
            finishedAt: "2020-01-21T21:20:32Z"
          }
        }
      end

      context "and slot is running" do
        it "releases slot" do
          expect { subject.perform(node: node) }.to change { slot.reload.status }.from("running").to("releasing")
        end

        it "performs ReleaseSlotJob" do
          expect(ReleaseSlotJob).to receive(:perform_later)
            .with(hash_including(runner_id: "job_name"))

          subject.perform(node: node)
        end
      end

      context "and slot is not running" do
        let(:slot_status) { :idle }

        it "does not release slot" do
          expect { subject.perform(node: node) }.to_not(change { slot.reload.status })
        end
      end
    end

    context "and runner capacity is reached" do
      let(:pods) do
        {
          pod_job_name => Kubeclient::Resource.new(
            metadata: {
              labels: {
                "job-name" => pod_job_name
              }
            },
            status: {
              phase: "Pending",
              conditions: [
                reason: "Unschedulable",
                message: "0/28 nodes are available: 26 node(s) didn't match node selector, 4 Insufficient cpu."
              ]
            }
          )
        }
      end

      it "mark node as capacity reached" do
        expect { subject.perform(node: node) }.to change(node, :runner_capacity_reached).to(true)
      end

      it "assigns error in task" do
        expect { subject.perform(node: node) }.to change { slot.current_task.reload.error }
          .to("Unschedulable: 0/28 nodes are available: 26 node(s) didn't match node selector, 4 Insufficient cpu.")
      end
    end

    it "does not remove container" do
      expect(RemoveRunnerJob).to_not receive(:perform_later)

      subject.perform(node: node)
    end
  end

  context "when slot does not exist" do
    let(:pod_job_name) { "other-job-name" }

    it "removes container" do
      expect(RemoveRunnerJob).to receive(:perform_later)
        .with(node: node, runner_id: pod_job_name)

      subject.perform(node: node)
    end
  end
end
