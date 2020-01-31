# frozen_string_literal: true

require "rails_helper"

RSpec.describe Runners::Kubernetes::RemoveRunner, type: :service do
  let(:node) { Fabricate.build(:node_kubernetes) }
  let(:kubernetes_client) { double(KubernetesClient) }
  let(:runner_id) { "xx-6ryfnh38" }

  before do
    allow(node).to receive(:kubernetes_client)
      .and_return(kubernetes_client)

    allow(kubernetes_client).to receive(:force_delete_pod)
      .with(pod_name: runner_id)
  end

  context "pod removal" do
    context "when pod exists in the cluster" do
      it "deletes pod" do
        expect(kubernetes_client).to receive(:force_delete_pod)
          .with(pod_name: runner_id)

        subject.perform(node: node, runner_id: runner_id)
      end
    end

    context "when pod does not exist in the cluster" do
      before do
        allow(kubernetes_client).to receive(:force_delete_pod)
          .and_raise(KubernetesClient::PodNotFoundError.new)
      end

      it "does not raise error" do
        expect { subject.perform(node: node, runner_id: runner_id) }.to_not raise_error
      end
    end

    context "when a network error happens" do
      before do
        allow(kubernetes_client).to receive(:force_delete_pod).and_raise(KubernetesClient::NetworkError)
      end

      it "raises the error" do
        expect { subject.perform(node: node, runner_id: runner_id) }.to raise_error(KubernetesClient::NetworkError)
      end
    end
  end
end
