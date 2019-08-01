class RunTasksForAllExecutionTypesJob < ApplicationJob
  queue_as :default

  def perform
    Slot.pluck(:execution_type).uniq.each do |execution_type|
      RunTasksJob.perform_later(execution_type: execution_type)
    end
  end
end
