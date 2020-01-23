# frozen_string_literal: true

require "rails_helper"

RSpec.describe Runners::Docker::FetchExecutionInfo, type: :service do
  let(:container_id) { "df782008cf45" }
  let(:node) { Fabricate(:node) }
  let(:slot) { Fabricate(:slot_running, node: node) }
  let(:task) { Fabricate(:task, container_id: container_id, slot: slot) }
  let(:container) { double(Docker::Container) }

  before do
    allow(::Docker::Container).to receive(:get)
      .with(container_id, anything, anything)
      .and_return(container)
  end

  it "creates an execution info" do
    expect_any_instance_of(Runners::Docker::CreateExecutionInfo).to receive(:perform)
      .with(container: container)

    subject.perform(task: task)
  end
end
