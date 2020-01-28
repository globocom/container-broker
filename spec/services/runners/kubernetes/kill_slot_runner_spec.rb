# frozen_string_literal: true

require "rails_helper"

RSpec.describe Runners::Kubernetes::KillSlotRunner, type: :service do
  let(:slot) { Fabricate(:slot, runner_id: runner_id) }
  let(:runner_id) { SecureRandom.hex }

  it "performs remove container service" do
    expect_any_instance_of(Runners::Kubernetes::RemoveRunner).to receive(:perform)
      .with(node: slot.node, runner_id: runner_id)

    subject.perform(slot: slot)
  end
end
