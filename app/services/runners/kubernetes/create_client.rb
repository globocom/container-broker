# frozen_string_literal: true

module Runners
  module Kubernetes
    class CreateClient
      attr_reader :node

      def perform(node:)
        @node = node

        raise(Runners::InvalidRunner, "Node must be a kubernetes runner") unless node.kubernetes?

        raise(Runners::InvalidConfig, "Invalid configuration (#{node.runner_config}) for kubernetes") unless valid?

        KubernetesClient.new(
          uri: node.hostname,
          bearer_token: node.runner_config["bearer_token"],
          namespace: node.runner_config["namespace"]
        )
      end

      private

      def valid?
        %w[bearer_token namespace nfs_server nfs_path node_selector].none? { |field| node.runner_config[field].blank? }
      end
    end
  end
end
