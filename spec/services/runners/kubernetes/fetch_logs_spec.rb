# frozen_string_literal: true

require "rails_helper"

RSpec.describe Runners::Kubernetes::FetchLogs, type: :service do
  let(:node) { Fabricate.build(:node_kubernetes) }
  let(:slot) { Fabricate.build(:slot, node: node) }
  let(:task) { Fabricate.build(:task, slot: slot, container_id: "container-id") }
  let(:response) { double(RestClient::Response, body: "logs") }
  let(:kubernetes_client) { double(KubernetesClient) }

  before do
    allow(node).to receive(:kubernetes_client).and_return(kubernetes_client)

    allow(kubernetes_client).to receive(:fetch_job_logs)
      .with(job_name: task.container_id)
      .and_return(response)
  end

  it "fetches job logs" do
    expect(subject.perform(task: task)).to eq("logs")
  end

  context "when receiving an error" do
    context "and it's bad request" do
      before do
        allow(kubernetes_client).to receive(:fetch_job_logs)
          .with(job_name: task.container_id)
          .and_raise(Kubeclient::HttpError.new(400, "message", nil))
      end

      it "returns nil" do
        expect(subject.perform(task: task)).to be_nil
      end
    end

    context "and it's another error" do
      before do
        allow(kubernetes_client).to receive(:fetch_job_logs)
          .with(job_name: task.container_id)
          .and_raise(Kubeclient::HttpError.new(404, "message", nil))
      end

      it "raises the error" do
        expect { subject.perform(task: task) }.to raise_error(Kubeclient::HttpError)
      end
    end
  end
end
