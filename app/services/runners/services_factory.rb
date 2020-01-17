# frozen_string_literal: true

module Runners
  class ServicesFactory
    class ServiceNotFoundForRunner < StandardError; end

    SERVICES = {
      kubernetes: {
        update_node_status: Runners::Kubernetes::UpdateNodeStatus,
        monitor_unresponsive_node: Runners::Kubernetes::MonitorUnresponsiveNode
      },
      docker: {
        update_node_status: Runners::Docker::UpdateNodeStatus,
        monitor_unresponsive_node: Runners::Docker::MonitorUnresponsiveNode
      }
    }.freeze

    def self.fabricate(node:, service:)
      service = SERVICES.dig(node.runner, service)

      raise ServiceNotFoundForRunner, "No service #{service} found for #{node.runner}" unless service

      service.new(node: node)
    end
  end
end
