# frozen_string_literal: true

module Runners
  module Kubernetes
    class RunTask
      NFS_NAME = "nfs"

      def perform(task:, slot:)
        job_name = create_job(task: task, node: slot.node)

        task.update!(container_id: job_name)
        task.mark_as_started!
        slot.mark_as_running(current_task: task, container_id: job_name)

        add_metric(task)

        task
      rescue StandardError => e
        message = "#{e.class}: #{e.message}"
        Rails.logger.debug("Error creating #{task}: #{message}")

        slot.release
        Rails.logger.debug("#{slot} released")

        task.update!(container_id: nil, error: message)
        Rails.logger.debug("#{task} updated with error message")

        add_metric(task)

        task.mark_as_retry
        Rails.logger.debug("#{task} marked as retry")
      end

      def create_job(task:, node:)
        node.kubernetes_client.create_job(
          job_name: generate_job_name(task: task),
          image: task.image,
          cmd: task.cmd,
          internal_mounts: internal_mounts(task: task, node: node),
          external_mounts: external_mounts(task: task, node: node),
          node_selector: node.kubernetes_config.node_selector
        )
      end

      def internal_mounts(task:, node:)
        return [] if task.ingest_storage_mount.blank?

        [
          {
            name: NFS_NAME,
            mountPath: task.ingest_storage_mount
          }
        ]
      end

      def external_mounts(task:, node:)
        return [] if task.ingest_storage_mount.blank?

        [
          {
            name: NFS_NAME,
            nfs: {
              server: node.kubernetes_config.nfs_server,
              path: node.kubernetes_config.nfs_path
            }
          }
        ]
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

      def generate_job_name(task:)
        "#{task.name}-#{SecureRandom.alphanumeric(8).downcase}"
      end
    end
  end
end
