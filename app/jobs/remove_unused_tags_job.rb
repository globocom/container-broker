# frozen_string_literal: true

class RemoveUnusedTagsJob < ApplicationJob
  queue_as :default

  def perform(*_args)
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
    remaining_values = Task.distinct(tag_expression(task_tag))
    task_tag.update!(values: remaining_values)
  end

  def tag_expression(task_tag)
    :"tags.#{task_tag.name}"
  end

  def any_task_referencing_tag?(task_tag)
    Task.where(tag_expression(task_tag).exists => true).exists?
  end
end
