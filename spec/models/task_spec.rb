require 'rails_helper'

RSpec.describe Task, type: :model do
  let(:now) { Time.zone.now }
  subject { Fabricate(:task) }

  context "for new tasks" do
    it "saves creation date" do
      allow(Time.zone).to receive(:now).and_return(now)
      expect(subject.created_at).to eq(now)
    end

    it "starts with waiting status" do
      expect(described_class.new).to be_waiting
    end

    it "convert all tags values to string" do
      task = Fabricate(:task, tags: {api_id: 12345})
      task.reload

      expect(task.tags["api_id"]).to eq("12345")
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
end
