# frozen_string_literal: true

require "rails_helper"

RSpec.describe MigrateTasksFromDeadNodeJob, type: :job do
  let(:node) { Fabricate(:node, status: "unavailable") }
  let(:slot) { Fabricate(:slot, node: node, status: "running", execution_type: "test") }
  let(:task) { Fabricate(:task, slot: slot, status: task_status) }
  let(:task_status) { "waiting" }
  let(:migrate_runner_instance) { double(MigrateRunner, migrate: nil) }

  let(:perform) { subject.perform(node: node) }

  before do
    slot.update(current_task: task)

    allow(MigrateRunner).to receive(:new)
      .with(runner_id: slot.runner_id)
      .and_return(migrate_runner_instance)
  end

  context "for started tasks" do
    let(:task_status) { "started" }

    it "changes task status to retry" do
      expect { perform }.to change(task, :status).to "retry"
    end

    it "try to run new tasks" do
      perform
      expect(RunTasksJob).to have_been_enqueued.at_least(1).times
    end
  end

  context "for starting tasks" do
    let(:task_status) { "starting" }

    it "changes task status to retry" do
      expect { perform }.to change(task, :status).to "retry"
    end

    it "try to run new tasks" do
      perform
      expect(RunTasksJob).to have_been_enqueued.at_least(1).times
    end
  end

  it "releases slot" do
    expect { perform }.to change(slot, :status).to("idle")
  end

  it "performs migrate runner id" do
    expect(migrate_runner_instance).to receive(:migrate)

    perform
  end
end
