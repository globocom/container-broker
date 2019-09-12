# frozen_string_literal: true

require "rails_helper"

RSpec.describe RunTasksForAllExecutionTypesJob, type: :job do
  before do
    Fabricate(:slot_idle, execution_type: "cpu")
    Fabricate(:slot_idle, execution_type: "cpu")
    Fabricate(:slot_idle, execution_type: "io")
  end

  it "enqueues RunTasksJob for cpu" do
    subject.perform
    expect(RunTasksJob).to have_been_enqueued.with(execution_type: "cpu").once
  end

  it "enqueues RunTasksJob for io" do
    subject.perform
    expect(RunTasksJob).to have_been_enqueued.with(execution_type: "io").once
  end
end
