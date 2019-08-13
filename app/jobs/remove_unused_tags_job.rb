# frozen_string_literal: true

class RemoveUnusedTagsJob < ApplicationJob
  queue_as :default

  def perform(*args)
    remove_unreferenced_tags
  end

  def remove_unreferenced_tags
    TaskTag.each do |task_tag|
      if any_task_referencing_tag?(task_tag)
        remove_unreferenced_tag_values(task_tag)
      else
        task_tag.destroy!
      end
    end
  end

  def remove_unreferenced_tag_values(task_tag)
    remaining_values = task_tag.values.select do |value|
      any_task_referencing_tag_value?(task_tag, value)
    end

    task_tag.update!(values: remaining_values)
  end

  def tag_expression(task_tag)
    :"tags.#{task_tag.name}"
  end

  def any_task_referencing_tag?(task_tag)
    Task.where(tag_expression(task_tag).exists => true).exists?
  end

  def any_task_referencing_tag_value?(task_tag, value)
    Task.where(tag_expression(task_tag) => value).exists?
  end
end
