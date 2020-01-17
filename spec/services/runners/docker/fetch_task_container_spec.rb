# frozen_string_literal: true

require "rails_helper"

RSpec.describe Runners::Docker::FetchTaskContainer, type: :service do
  let(:container_id) { SecureRandom.hex }
  let(:node) { Fabricate(:node) }
  let(:slot) { Fabricate(:slot, node: node) }
  let(:task) { Fabricate(:task, slot: slot, container_id: container_id) }
  let(:docker_connection) { double("Docker::Connection") }

  before do
    allow(node).to receive(:docker_connection).and_return(docker_connection)
  end

  it "performs Docker::Container.get" do
    expect(::Docker::Container).to receive(:get)
      .with(container_id, any_args, docker_connection)

    subject.perform(task: task)
  end
end
