# frozen_string_literal: true

module Runners
  module Kubernetes
    class RunTask
      NFS_NAME = "nfs"

      def perform(task:, slot:, runner_id:)
        create_pod(task: task, node: slot.node, runner_id: runner_id)
      rescue KubernetesClient::NetworkError => e then
        raise Node::NodeConnectionError, "#{e.class}: #{e.message}"
      end

      private

      def create_pod(task:, node:, runner_id:)
        CreateClient.new.perform(node: node).create_pod(
          pod_name: runner_id,
          image: task.image,
          cmd: task.cmd,
          internal_mounts: internal_mounts(task: task),
          external_mounts: external_mounts(task: task),
          node_selector: node.runner_config["node_selector"]
        )
      end

      def filer(task:)
        Filer.new.perform(task_storage_mounts: task.storage_mounts)
      end

      def internal_mounts(task:)
        filer(task: task)[:internal]
      end

      def external_mounts(task:)
        filer(task: task)[:external]
      end

      def add_metric(task)
        Metrics.new("tasks").count(
          task_id: task.id,
          name: task&.name,
          type: task&.execution_type,
          slot: task&.slot&.name,
          node: task&.slot&.node&.name,
          started_at: task.started_at,
          duration: task.milliseconds_waiting,
          error: task.error,
          status: task.status
        )
      end
    end
  end
end
