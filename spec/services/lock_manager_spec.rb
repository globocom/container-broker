require 'rails_helper'

RSpec.describe LockManager do
  subject do
    described_class.new(type: "test-lock", id: 2, expire: expire_time, wait: wait)
  end
  let(:original_lock_duration) { 1 }
  let(:expire_time) { 2 }
  let(:object) { double }
  let(:redis_client) { double("RedisClient") }

  before do
    allow(object).to receive(:update)
    allow(redis_client).to receive(:set)
    allow(redis_client).to receive(:del)
    allow(subject).to receive(:redis_client).and_return(redis_client)
  end

  context "when lock needs to wait" do
    let(:wait) { true }

    context "and it is locked" do
      before do
        allow(subject).to receive(:locked).and_return(false, false, true)
      end

      it "tries locking until achieve lock" do
        expect(subject).to receive(:try_lock).thrice
        subject.lock {}
      end

      it "yields block when lock aquired" do
        expect {|block| subject.lock &block }.to yield_control
      end
    end
  end

  context "when lock does not need to wait" do
    let(:wait) { false }

    context "and it is locked" do
      before do
        allow(subject).to receive(:locked).and_return(false)
      end

      it "does not yield block when lock aquired" do
        expect {|block| subject.lock &block }.to_not yield_control
      end

      it "returns false" do
        expect(subject.lock{}).to eq(false)
      end
    end

    context "and it is not locked" do
      before do
        allow(subject).to receive(:locked).and_return(true)
      end

      it "yields block when lock aquired" do
        expect {|block| subject.lock &block }.to yield_control
      end
    end
  end

  context "redis receive correct messages" do
    let(:wait) { false }
    let(:expire_time) { 2 }

    it "when not locked" do
      expect(redis_client).to receive(:set).with("lockmanager-test-lock-2", 1, {nx: true, ex: 2})
      subject.try_lock
    end
  end
end
