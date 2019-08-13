# frozen_string_literal: true

require 'rails_helper'

RSpec.describe NodeTaskAcceptance do
  let(:node) { "<defined-in-each-context>" }

  subject { described_class.new(node: node) }

  context "accepting new tasks" do
    let(:node) { Fabricate(:node, accept_new_tasks: false) }

    it "change to true" do
      expect { subject.accept! }
        .to change(node, :accept_new_tasks?).to(true)
    end

    it "calls RunTasksJob" do
      subject.accept!

      expect(RunTasksForAllExecutionTypesJob).to have_been_enqueued
    end
  end

  context "rejecting new tasks" do
    let(:node) { Fabricate(:node, accept_new_tasks: true) }

    it "change to false" do
      expect { subject.reject! }
        .to change(node, :accept_new_tasks?).to(false)
    end
  end
end
