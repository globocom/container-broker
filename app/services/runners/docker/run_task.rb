# frozen_string_literal: true

module Runners
  module Docker
    class RunTask
      def perform(task:, slot:)
        Rails.logger.debug("Performing RunTaskJob for #{task} #{slot}")

        pull_image(task: task, slot: slot)
        Rails.logger.debug("Image pulled for #{task} #{slot}")

        container = create_container(task: task, slot: slot)
        Rails.logger.debug("Container #{container.id} created for #{task} #{slot}")

        container.start
        Rails.logger.debug("Container #{container.id} started")

        container.id
      rescue Excon::Error, ::Docker::Error::TimeoutError => e then
        message = "Docker connection error: #{e.message}"
        message += "\n#{e.response.body}" if e.respond_to?(:response)
        raise Node::NodeConnectionError, message
      rescue ::Docker::Error::NotFoundError => e
        raise "Docker image not found: #{e.message}"
      end

      private

      def pull_image(task:, slot:)
        return if ::Docker::Image.exist?(task.image, {}, slot.node.docker_connection)

        image_name, image_tag = task.image.split(":")
        image_tag ||= "latest"

        ::Docker::Image.create({ "fromImage" => image_name, "tag" => image_tag }, nil, slot.node.docker_connection)
      end

      def create_container(task:, slot:)
        binds = []
        binds << Filer::Container.bind(task.storage_mount) if task.storage_mount.present?
        binds << Filer::Ingest.bind(task.ingest_storage_mount) if task.ingest_storage_mount.present?

        ::Docker::Container.create(
          {
            "Image" => task.image,
            "HostConfig" => {
              "Binds" => binds,
              "NetworkMode" => ENV["DOCKER_CONTAINERS_NETWORK"].to_s
            },
            "Entrypoint" => [],
            "Cmd" => ["sh", "-c", task.cmd]
          },
          slot.node.docker_connection
        )
      end
    end
  end
end
