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
  end

end
