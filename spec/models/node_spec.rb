require 'rails_helper'

RSpec.describe Node, type: :model do

  describe "#update_usage" do
    before do
      Slot.create(node: subject, status: "running")
      Slot.create(node: subject, status: "attaching")
      Slot.create(node: subject, status: "idle")
      Slot.create(node: subject, status: "releasing")
    end

    it "sets usage to percentual of used slots" do
      expect{subject.update_usage}.to change(subject, :usage_percent).to(75)
    end
  end
end
