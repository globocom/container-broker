# frozen_string_literal: true

require "rails_helper"

RSpec.describe Runners::Kubernetes::FetchLogs, type: :service do
  let(:node) { Fabricate.build(:node_kubernetes) }
  let(:slot) { Fabricate.build(:slot, node: node) }
  let(:task) { Fabricate.build(:task, slot: slot, runner_id: "runner-id") }
  let(:response) { "logs" }
  let(:kubernetes_client) { double(KubernetesClient) }

  before do
    allow(node).to receive(:kubernetes_client).and_return(kubernetes_client)

    allow(kubernetes_client).to receive(:fetch_pod_logs)
      .with(pod_name: task.runner_id)
      .and_return(response)
  end

  it "fetches pod logs" do
    expect(subject.perform(task: task)).to eq("logs")
  end

  context "when receiving an error" do
    context "and it's log not found" do
      before do
        allow(kubernetes_client).to receive(:fetch_pod_logs)
          .with(pod_name: task.runner_id)
          .and_raise(KubernetesClient::LogsNotFoundError)
      end

      it "returns the error as the log" do
        expect(subject.perform(task: task)).to eq("Logs not found")
      end
    end

    context "and the error is that the pod does not exist" do
      before do
        allow(kubernetes_client).to receive(:fetch_pod_logs)
          .with(pod_name: task.runner_id)
          .and_raise(KubernetesClient::PodNotFoundError)
      end

      it "raises the error" do
        expect { subject.perform(task: task) }.to raise_error(Runners::RunnerIdNotFoundError)
      end
    end

    context "and it's other error" do
      before do
        allow(kubernetes_client).to receive(:fetch_pod_logs)
          .with(pod_name: task.runner_id)
          .and_raise(KubernetesClient::NetworkError)
      end

      it "raises the error" do
        expect { subject.perform(task: task) }.to raise_error(KubernetesClient::NetworkError)
      end
    end
  end
end
