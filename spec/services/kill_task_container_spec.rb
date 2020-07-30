# frozen_string_literal: true

require "rails_helper"

RSpec.describe KillTaskContainer do
  let(:slot) { Fabricate.build(:slot_running) }
  let(:task) { Fabricate.build(:task, slot: slot, status: task_status) }
  let(:kill_slot_runner_instance) { instance_double(Runners::Docker::KillSlotRunner, perform: nil) }

  subject(:perform) { described_class.new(task: task).perform }

  before do
    allow(task.slot.node).to receive(:runner_service)
      .with(:kill_slot_runner)
      .and_return(kill_slot_runner_instance)
  end

  context "when task is running" do
    let(:task_status) { :started }

    it "calls kill_slot_runner" do
      perform

      expect(kill_slot_runner_instance)
        .to have_received(:perform).with(slot: slot)
    end
  end

  context "when task is not running" do
    let(:task_status) { :waiting }

    it { expect { perform }.to raise_error(described_class::TaskNotRunningError) }
  end
end
