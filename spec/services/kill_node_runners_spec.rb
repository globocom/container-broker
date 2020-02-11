# frozen_string_literal: true

require "rails_helper"

RSpec.describe KillNodeRunners do
  let(:node) { Fabricate(:node) }
  let(:running_slot) { Fabricate(:slot_running, node: node) }
  let(:idle_slot) { Fabricate(:slot_idle, node: node) }
  let(:attaching_slot) { Fabricate(:slot_attaching, node: node) }
  let(:releasing_slot) { Fabricate(:slot_releasing, node: node) }
  let(:slot) { "<defined-in-each-context>" }

  let(:docker_kill_slot_runner) { double(Runners::Docker::KillSlotRunner) }

  subject { described_class.new(node: node) }

  before do
    allow(node).to receive(:runner_service)
      .with(:kill_slot_runner)
      .and_return(docker_kill_slot_runner)

    allow(docker_kill_slot_runner).to receive(:perform).with(slot: slot)
  end

  context "for idle slots" do
    let(:slot) { idle_slot }

    it "does not kill containers" do
      expect(docker_kill_slot_runner).to_not receive(:perform)

      subject.perform
    end
  end

  context "for attaching slots" do
    let(:slot) { attaching_slot }

    it "does not kill containers" do
      expect(docker_kill_slot_runner).to_not receive(:perform)

      subject.perform
    end
  end

  context "for running slots" do
    let(:slot) { running_slot }

    it "performs the service" do
      expect(docker_kill_slot_runner).to receive(:perform).once

      subject.perform
    end
  end

  context "for releasing slots" do
    let(:slot) { releasing_slot }

    it "does not kill containers" do
      expect(docker_kill_slot_runner).to_not receive(:perform)

      subject.perform
    end
  end
end
