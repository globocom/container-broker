# frozen_string_literal: true

module Runners
  module Kubernetes
    class Filer
      class InvalidMountName < StandardError; end

      attr_reader :task_storage_mounts

      def perform(task_storage_mounts:)
        @task_storage_mounts = task_storage_mounts

        {
          internal: internal,
          external: external
        }
      end

      private

      def internal
        task_storage_mounts.map do |task_mount_name, task_mount_path|
          {
            name: task_mount_name,
            mountPath: task_mount_path
          }
        end
      end

      def external
        task_storage_mounts.map do |task_mount_name, _task_mount_path|
          node_mount_path = Settings.to_hash[:storage_mounts][:kubernetes][task_mount_name.to_sym]

          raise InvalidMountName unless node_mount_path

          node_mount_path.merge(name: task_mount_name)
        end
      end
    end
  end
end
