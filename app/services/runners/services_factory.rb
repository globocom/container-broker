# frozen_string_literal: true

class Runners::ServicesFactory
  class ServiceNotFoundForRunner < StandardError; end

  SERVICES = {
    kubernetes: {
      update_node_status: Runners::Kubernetes::UpdateNodeStatus,
      node_availability: Runners::Kubernetes::NodeAvailability,
      run_task: Runners::Kubernetes::RunTask,
      kill_slot_container: Runners::Kubernetes::KillSlotContainer,
      remove_container: Runners::Kubernetes::RemoveContainer,
      fetch_logs: Runners::Kubernetes::FetchLogs,
      fetch_execution_info: Runners::Kubernetes::FetchExecutionInfo
    },
    docker: {
      update_node_status: Runners::Docker::UpdateNodeStatus,
      node_availability: Runners::Docker::NodeAvailability,
      run_task: Runners::Docker::RunTask,
      kill_slot_container: Runners::Docker::KillSlotContainer,
      fetch_task_container: Runners::Docker::FetchTaskContainer,
      remove_container: Runners::Docker::RemoveContainer,
      fetch_logs: Runners::Docker::FetchLogs,
      fetch_execution_info: Runners::Docker::FetchExecutionInfo
    }
  }.freeze

  def self.fabricate(runner:, service:)
    service_class = SERVICES.dig(runner.to_sym, service)

    raise ServiceNotFoundForRunner, "No service #{service} found for #{runner}" unless service_class

    service_class.new
  end
end
