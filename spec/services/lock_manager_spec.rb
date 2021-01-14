# frozen_string_literal: true

require "rails_helper"

RSpec.describe LockManager do
  let(:lock_args) do
    { type: "test-lock",
      id: 2,
      expire: expire_time,
      wait: wait }
  end
  let(:original_lock_duration) { 1 }
  let(:expire_time) { 5 }
  let(:object) { double }

  subject { described_class.new(**lock_args) }

  after { subject.unlock! }

  context "when lock needs to wait" do
    let(:wait) { true }

    context "and it is locked" do
      before do
        allow(subject).to receive(:locked).and_return(false, false, true)
      end

      it "tries locking until achieve lock" do
        expect(subject).to receive(:try_lock).thrice
        subject.lock
      end

      context "with a block" do
        it "yields when lock acquired" do
          expect { |block| subject.lock &block }.to yield_control
        end
      end

      context "without a block" do
        it "returns true when lock acquired" do
          expect(subject.lock!).to be_truthy
        end
      end
    end
  end

  context "when lock does not need to wait" do
    let(:wait) { false }

    context "and it is locked" do
      before { described_class.new(**lock_args).lock! }
      after { described_class.new(**lock_args).lock! }

      context "with a block" do
        it "does not yield when lock acquired" do
          expect { |block| subject.lock &block }.to_not yield_control
        end

        it "returns false" do
          expect(subject.lock).to be_falsey
        end

        it "does not release the lock" do
          subject.lock
          expect(subject.locked).to be_falsey
        end
      end

      context "without a block" do
        it "returns false" do
          expect(subject.lock!).to be_falsey
        end
      end
    end

    context "and it is not locked" do
      before do
        allow(subject).to receive(:locked).and_return(true)
      end

      it "yields block when lock acquired" do
        expect { |block| subject.lock &block }.to yield_control
      end
    end
  end

  context "unlocking" do
    before { subject.lock! }

    let(:wait) { false }

    it "unlocks and allow a new lock to be performed" do
      subject.unlock!

      expect(subject.lock!).to be_truthy
    end
  end

  context "redis receive correct messages" do
    let(:wait) { false }
    let(:expire_time) { 5 }

    it "when not locked" do
      expect_any_instance_of(Redis).to receive(:set).with("lockmanager-test-lock-2", 1, nx: true, ex: 5)

      subject.try_lock
    end
  end
end
