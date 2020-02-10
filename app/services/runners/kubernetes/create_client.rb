# frozen_string_literal: true

module Runners::Kubernetes
  class CreateClient
    def perform(node:)
      raise(Runners::InvalidRunner, "Node must be a kubernetes runner") unless node.kubernetes?

      KubernetesClient.new(
        uri: node.hostname,
        bearer_token: node.kubernetes_config.bearer_token,
        namespace: node.kubernetes_config.namespace
      )
    end
  end
end
