# frozen_string_literal: true

class AddTaskTagsJob < ContainerBrokerBaseJob
  extend RequestIdFromTask

  queue_as :default

  def perform(task:)
    task.tags.each_key do |tag_name|
      TaskTag.find_or_create_by(name: tag_name.to_s)
    end
  end
end
