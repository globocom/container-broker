# frozen_string_literal: true

require "rails_helper"

RSpec.describe Runners::Docker::CreateConnection, type: :model do
  context "when node is docker" do
    let(:node) { Fabricate.build(:node_docker) }

    it "has a docker connection" do
      expect(subject.perform(node: node)).to be_a(::Docker::Connection)
    end
  end

  context "when node is kubernetes" do
    let(:node) { Fabricate.build(:node_kubernetes) }

    it "raises an error when getting docker connection" do
      expect { subject.perform(node: node) }.to raise_error(Runners::InvalidRunner)
    end
  end
end
