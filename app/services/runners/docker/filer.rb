# frozen_string_literal: true

module Runners
  module Docker
    class Filer
      class InvalidMountName < StandardError; end

      def perform(task_storage_mounts:)
        task_storage_mounts.map do |task_mount_name, task_mount_path|
          node_mount_path = Settings.storage_mounts.docker[task_mount_name]

          raise InvalidMountName unless node_mount_path

          [node_mount_path, task_mount_path].join(":")
        end
      end
    end
  end
end
