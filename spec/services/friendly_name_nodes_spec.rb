# frozen_string_literal: true

require "rails_helper"

RSpec.describe FriendlyNameNodes, type: :service do
  let(:friendly_name_slots_instance) { double(FriendlyNameSlots) }

  before do
    allow(FriendlyNameSlots).to receive(:new)
      .with(node: node)
      .and_return(friendly_name_slots_instance)

    allow(friendly_name_slots_instance).to receive(:perform)
  end

  context "for docker node" do
    let!(:node) { Fabricate(:node_docker) }

    it "renames node" do
      expect do
        subject.perform
        node.reload
      end.to change(node, :name).to("n01d")
    end

    it "renames slots" do
      expect(friendly_name_slots_instance).to receive(:perform)

      subject.perform
    end
  end

  context "for kuberntes node" do
    let!(:node) { Fabricate(:node_kubernetes) }

    it "renames node" do
      expect do
        subject.perform
        node.reload
      end.to change(node, :name).to("n01k")
    end

    it "renames slots" do
      expect(friendly_name_slots_instance).to receive(:perform)

      subject.perform
    end
  end
end
