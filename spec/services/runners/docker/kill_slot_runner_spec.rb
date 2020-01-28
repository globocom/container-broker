# frozen_string_literal: true

require "rails_helper"

RSpec.describe Runners::Docker::KillSlotRunner, type: :service do
  let(:slot) { Fabricate(:slot, runner_id: runner_id) }
  let(:runner_id) { SecureRandom.hex }
  let(:container) { double("Docker::Container") }

  context "when a container is running" do
    before do
      allow(Docker::Container).to receive(:get).with(runner_id, {}, kind_of(Docker::Connection)).and_return(container)
    end

    it "kills the container" do
      expect(container).to receive(:kill!)

      subject.perform(slot: slot)
    end
  end

  context "when container is not found" do
    before do
      allow(Docker::Container).to receive(:get).with(runner_id, {}, kind_of(Docker::Connection)).and_raise(Docker::Error::NotFoundError)
    end

    it "does not raise error" do
      expect { subject.perform(slot: slot) }.to_not raise_error
    end
  end

  context "when a communication error happens" do
    before do
      allow(Docker::Container).to receive(:get).with(runner_id, {}, kind_of(Docker::Connection)).and_raise(Excon::Error)
    end

    it "does not raise error" do
      expect { subject.perform(slot: slot) }.to_not raise_error
    end
  end
end
