# frozen_string_literal: true

module Runners
  module Docker
    class RunTask
      def perform(task:, slot:, runner_id:)
        Rails.logger.debug("Performing Docker::RunTask for #{task} #{slot}")

        pull_image(task: task, slot: slot)
        Rails.logger.debug("Image pulled for #{task} #{slot}")

        container = create_container(task: task, slot: slot, name: runner_id)
        Rails.logger.debug("Container #{container.id} created for #{task} #{slot} with name #{runner_id}")

        container.start
        Rails.logger.debug("Container #{container.id} started")

        runner_id
      rescue Excon::Error, ::Docker::Error::TimeoutError => e then
        message = "Docker connection error: #{e.message}"
        message += "\n#{e.response.body}" if e.respond_to?(:response)
        raise Node::NodeConnectionError, message
      rescue ::Docker::Error::NotFoundError => e
        raise "Docker image not found: #{e.message}"
      end

      private

      def pull_image(task:, slot:)
        return if ::Docker::Image.exist?(task.image, {}, CreateConnection.new.perform(node: slot.node))

        image_name, image_tag = task.image.split(":")
        image_tag ||= "latest"

        ::Docker::Image.create({ "fromImage" => image_name, "tag" => image_tag }, nil, CreateConnection.new.perform(node: slot.node))
      end

      def create_container(task:, slot:, name:)
        binds = []
        binds << Filer::Container.bind(task.storage_mount) if task.storage_mount.present?
        binds << Filer::Ingest.bind(task.ingest_storage_mount) if task.ingest_storage_mount.present?

        user = [
          Settings.run_container_as.user_id,
          Settings.run_container_as.group_id
        ].join(":")

        ::Docker::Container.create(
          {
            "name" => name,
            "Image" => task.image,
            "User" => user,
            "HostConfig" => {
              "Binds" => binds,
              "NetworkMode" => ENV["DOCKER_CONTAINERS_NETWORK"].to_s
            },
            "Entrypoint" => [],
            "Cmd" => ["sh", "-c", task.cmd]
          },
          CreateConnection.new.perform(node: slot.node)
        )
      end
    end
  end
end
