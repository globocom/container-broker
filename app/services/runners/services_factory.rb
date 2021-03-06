# frozen_string_literal: true

module Runners
  class ServicesFactory
    class ServiceNotFoundForRunner < StandardError; end

    SERVICES = {
      kubernetes: {
        update_node_status: Runners::Kubernetes::UpdateNodeStatus,
        node_availability: Runners::Kubernetes::NodeAvailability,
        run_task: Runners::Kubernetes::RunTask,
        kill_slot_runner: Runners::Kubernetes::KillSlotRunner,
        remove_runner: Runners::Kubernetes::RemoveRunner,
        fetch_logs: Runners::Kubernetes::FetchLogs,
        fetch_execution_info: Runners::Kubernetes::FetchExecutionInfo,
        filer: Runners::Kubernetes::Filer
      },
      docker: {
        update_node_status: Runners::Docker::UpdateNodeStatus,
        node_availability: Runners::Docker::NodeAvailability,
        run_task: Runners::Docker::RunTask,
        kill_slot_runner: Runners::Docker::KillSlotRunner,
        remove_runner: Runners::Docker::RemoveRunner,
        fetch_logs: Runners::Docker::FetchLogs,
        fetch_execution_info: Runners::Docker::FetchExecutionInfo,
        filer: Runners::Docker::Filer
      }
    }.freeze

    def self.fabricate(runner:, service:)
      service_class = SERVICES.dig(runner.to_sym, service)

      raise ServiceNotFoundForRunner, "No service #{service} found for #{runner}" unless service_class

      service_class.new
    end
  end
end
