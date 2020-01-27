# frozen_string_literal: true

require "rails_helper"

RSpec.describe Runners::Docker::FetchExecutionInfo, type: :service do
  let(:node) { Fabricate(:node) }
  let(:slot) { Fabricate(:slot_running, node: node) }
  let(:task) { Fabricate(:task, slot: slot) }
  let(:container) { double(Docker::Container) }
  let(:execution_info) { double(Runners::ExecutionInfo) }

  before do
    allow_any_instance_of(Runners::Docker::FetchTaskContainer).to receive(:perform)
      .with(task: task)
      .and_return(container)
  end

  it "uses CreateExecutionInfo service" do
    expect_any_instance_of(Runners::Docker::CreateExecutionInfo).to receive(:perform)
      .with(container: container)
      .and_return(execution_info)

    subject.perform(task: task)
  end

  context "creates an execution info" do
    before do
      allow_any_instance_of(Runners::Docker::CreateExecutionInfo).to receive(:perform)
        .with(container: container)
        .and_return(execution_info)
    end

    it "creates an execution info" do
      expect(subject.perform(task: task)).to eq(execution_info)
    end
  end
end
