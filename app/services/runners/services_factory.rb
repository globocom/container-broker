# frozen_string_literal: true

module Runners
  class ServicesFactory
    class ServiceNotFoundForRunner < StandardError; end

    SERVICES = {
      kubernetes: {
        update_node_status: Runners::Kubernetes::UpdateNodeStatus,
        monitor_unresponsive_node: Runners::Kubernetes::MonitorUnresponsiveNode,
        run_task: Runners::Kubernetes::RunTask
      },
      docker: {
        update_node_status: Runners::Docker::UpdateNodeStatus,
        monitor_unresponsive_node: Runners::Docker::MonitorUnresponsiveNode,
        run_task: Runners::Docker::RunTask
      }
    }.freeze

    def self.fabricate(runner:, service:)
      service_class = SERVICES.dig(runner.to_sym, service)

      raise ServiceNotFoundForRunner, "No service #{service} found for #{runner}" unless service_class

      service_class.new
    end
  end
end
