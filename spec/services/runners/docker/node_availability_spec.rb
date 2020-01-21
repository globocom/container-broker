# frozen_string_literal: true

require "rails_helper"

RSpec.describe Runners::Docker::NodeAvailability, type: :service do
  let(:node) { Fabricate(:node) }
  let(:docker_connection) { double(::Docker::Connection) }
  before { allow(node).to receive(:docker_connection).and_return(docker_connection) }

  it "fetches docker info" do
    expect(::Docker).to receive(:info).with(docker_connection)

    subject.perform(node: node)
  end
end
