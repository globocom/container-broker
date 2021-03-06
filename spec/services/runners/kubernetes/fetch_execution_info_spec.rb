# frozen_string_literal: true

require "rails_helper"

RSpec.describe Runners::Kubernetes::FetchExecutionInfo, type: :service do
  let(:kubernetes_client_instance) { double(KubernetesClient) }
  let(:node) { Fabricate(:node_kubernetes) }
  let(:pod_name) { "pod-name" }
  let(:slot) { Fabricate(:slot_running, node: node) }
  let(:task) { Fabricate(:task, runner_id: pod_name, slot: slot) }
  let(:pod) { Kubeclient::Resource.new(metadata: { name: pod_name }) }

  before do
    allow_any_instance_of(Runners::Kubernetes::CreateClient).to receive(:perform).with(node: node).and_return(kubernetes_client_instance)

    allow(kubernetes_client_instance).to receive(:fetch_pod)
      .with(pod_name: pod_name)
      .and_return(pod)
  end

  it "fetches pod from kubernetes client" do
    expect(kubernetes_client_instance).to receive(:fetch_pod).with(pod_name: pod_name)

    subject.perform(task: task)
  end

  it "creates execution info with pod" do
    expect_any_instance_of(Runners::Kubernetes::CreateExecutionInfo).to receive(:perform).with(pod: pod)

    subject.perform(task: task)
  end

  it "returns the execution info" do
    expect(subject.perform(task: task)).to be_a(Runners::ExecutionInfo)
  end
end
