# frozen_string_literal: true

class AddTaskTagsJob < ApplicationJob
  queue_as :default

  def perform(task:)
    task.tags.each do |name, value|
      tag = TaskTag.find_or_create_by(name: name.to_s)
      unless tag.values.include?(value)
        tag.values << value
        tag.save
      end
    end
  end
end
