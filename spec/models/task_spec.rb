# frozen_string_literal: true

require "rails_helper"

RSpec.describe Task, type: :model do
  let(:now) { Time.zone.now }
  let(:execution_type) { "test-type1" }
  subject { Fabricate(:task, execution_type: execution_type) }

  context "for new tasks" do
    it "saves creation date" do
      allow(Time.zone).to receive(:now).and_return(now)
      expect(subject.created_at).to eq(now)
    end

    it "starts with waiting status" do
      expect(described_class.new).to be_waiting
    end

    it "convert all tags values to string" do
      task = Fabricate(:task, tags: { api_id: 12_345 })
      task.reload

      expect(task.tags["api_id"]).to eq("12345")
    end

    it "calculates duration" do
      expect(subject.seconds_running).to be_nil
    end
  end

  context "with an invalid execution type" do
    let(:execution_type) { "invalid_type" }
    it "raises validation error" do
      expect { subject }.to raise_error(Mongoid::Errors::Validations)
    end
  end

  context "for started tasks" do
    subject do
      Fabricate(:task, started_at: "2018-01-25 15:32:10", finished_at: nil, status: "started")
    end

    before do
      allow(Time.zone).to receive(:now).and_return(Time.zone.parse("2018-01-25 15:33:00"))
    end

    it "calculates duration" do
      expect(subject.seconds_running).to eq(50)
    end
  end

  context "for completed tasks" do
    subject do
      Fabricate(:task, started_at: "2018-01-25 15:32:10", finished_at: "2018-01-25 15:32:32", status: "completed")
    end

    it "calculates duration" do
      expect(subject.seconds_running).to eq(22.seconds)
    end
  end

  context "for failing tasks" do
    context "with start and finish timestamps" do
      subject do
        Fabricate(:task, started_at: "2018-01-25 15:32:10", finished_at: "2018-01-25 15:32:32", status: "failed")
      end

      it "calculates duration" do
        expect(subject.seconds_running).to eq(22.seconds)
      end
    end

    context "without start and finish timestamps" do
      subject do
        Fabricate(:task, started_at: nil, finished_at: nil, status: "failed")
      end

      it "does not calculate duration" do
        expect(subject.seconds_running).to be_nil
      end
    end
  end
end
