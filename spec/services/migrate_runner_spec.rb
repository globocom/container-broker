# frozen_string_literal: true

require "rails_helper"

RSpec.describe MigrateRunner do
  let(:runner_id) { "runner_id" }

  subject { described_class.new(runner_id: runner_id) }

  before { described_class.redis_client.flushall }

  context "when migrated" do
    before { subject.migrate }

    it { is_expected.to be_migrated }
  end

  context "when not migrated" do
    it { is_expected.to_not be_migrated }
  end
end
