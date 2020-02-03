# frozen_string_literal: true

RSpec.describe Runners::ExecutionInfo do
  subject(:execution_info) do
    described_class.new(status: status, exit_code: 0)
  end

  context "when created with status success" do
    let(:status) { "success" }
    it { is_expected.to be_success }
    it { is_expected.to be_terminated }
  end

  context "when created with status error" do
    let(:status) { "error" }
    it { is_expected.to be_error }
    it { is_expected.to be_terminated }
  end

  context "when created with status running" do
    let(:status) { "running" }
    it { is_expected.to be_running }
  end

  context "when created with status pending" do
    let(:status) { "pending" }
    it { is_expected.to be_pending }
  end

  context "when created with status exited" do
    let(:status) { "exited" }

    it { is_expected.to be_terminated }

    it "raises error when try to get success" do
      expect { subject.success? }.to raise_error(Runners::UnknownCompletionInformation)
    end

    it "raises error when try to get error" do
      expect { subject.error? }.to raise_error(Runners::UnknownCompletionInformation)
    end
  end
end
