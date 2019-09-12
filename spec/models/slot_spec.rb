# frozen_string_literal: true

require "rails_helper"

RSpec.describe Slot, type: :model do
  context "when creating slots" do
    let (:execution_type) { "defined-in-each-context" }
    subject { Fabricate(:slot, execution_type: execution_type) }

    context "with a valid execution type" do
      let(:execution_type) { "io1" }

      it "is valid" do
        expect(subject).to be_valid
      end
    end

    context "with an invalid execution type" do
      let(:execution_type) { "invalid_symbol" }

      it "raises validation error" do
        expect { subject }.to raise_error(Mongoid::Errors::Validations)
      end
    end
  end
end
