# frozen_string_literal: true

RSpec.describe Runners::Kubernetes::CreateClient do
  context "for a kubernetes node" do
    let(:node) { Fabricate(:node_kubernetes) }

    context "creates a kubernetes client" do
      it "with hostname" do
        expect(KubernetesClient).to receive(:new).with(hash_including(uri: node.hostname))

        subject.perform(node: node)
      end

      it "with bearer token" do
        expect(KubernetesClient).to receive(:new).with(hash_including(bearer_token: node.kubernetes_config.bearer_token))

        subject.perform(node: node)
      end

      it "with namespace" do
        expect(KubernetesClient).to receive(:new).with(hash_including(namespace: node.kubernetes_config.namespace))

        subject.perform(node: node)
      end
    end
  end

  context "for another runner type node" do
    let(:node) { Fabricate(:node_docker) }

    it "raises an error" do
      expect { subject.perform(node: node) }.to raise_error(Runners::InvalidRunner)
    end
  end
end
