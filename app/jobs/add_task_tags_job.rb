# frozen_string_literal: true

class AddTaskTagsJob < ApplicationJob
  extend RequestIdFromTask

  queue_as :default

  def perform(task:)
    task.tags.keys.each do |tag_name|
      TaskTag.find_or_create_by(name: tag_name.to_s)
    end
  end
end
