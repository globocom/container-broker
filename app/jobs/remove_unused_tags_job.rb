# frozen_string_literal: true

class RemoveUnusedTagsJob < ApplicationJob
  queue_as :default

  def perform(*_args)
    remove_unreferenced_tags
  end

  def remove_unreferenced_tags
    TaskTag
      .all
      .to_a
      .reject { |task_tag| any_task_referencing_tag?(task_tag) }
      .each(&:destroy!)
  end

  def tag_expression(task_tag)
    :"tags.#{task_tag.name}"
  end

  def any_task_referencing_tag?(task_tag)
    Task.where(tag_expression(task_tag).exists => true).exists?
  end
end
