require 'rails_helper'

RSpec.describe MonitorUnresponsiveNodeJob, type: :job do

  context "when node is available" do
    let(:node) { Node.create!(status: "unavailable", last_error: "connection error", hostname: "localhost") }
    before { allow(Docker).to receive(:info) { "ok" } }

    it "marks node available again" do
      expect { subject.perform(node: node) }.to change(node, :status).to("available")
    end

    it "clears last error" do
      expect { subject.perform(node: node) }.to change(node, :last_error).to(nil)
    end
  end

  context "when node still unavailable" do
    let(:node) { Node.create!(available: true, hostname: "localhost") }
    before { allow(Docker).to receive(:info).and_raise("error getting docker info") }

    it "marks node as unavailable" do
      expect { subject.perform(node: node) }.to_not change(node, :available)
    end

    it "sets last error" do
      expect { subject.perform(node: node) }.to change(node, :last_error).to("error getting docker info")
    end
  end
end
