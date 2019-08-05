require 'rails_helper'

RSpec.describe DeleteNode, type: :service do
  let(:node) { Fabricate(:node) }

  subject { described_class.new(node: node) }

  before { Fabricate(:slot_idle, node: node) }

  context "when node is not accepting tasks" do
    let(:node) { Fabricate(:node, accept_new_tasks: false)}

    context "and there is no slots running" do
      it "deletes the node" do
        expect { subject.perform }
          .to change { Node.find(node.id) }.from(node).to(nil)
      end

      it "does not raises error" do
        expect { subject.perform }.to_not raise_error
      end
    end

    context "and there are slots running" do
      before do
        Fabricate(:slot_running, node: node)
      end

      it "does not delete the node" do
        expect do
          subject.perform rescue nil
        end.to_not change { Node.find(node.id) }
      end

      it "raises an error" do
        expect { subject.perform }.to raise_error(described_class::NodeWithRunningSlotsError)
      end
    end
  end

  context "when node is accepting tasks" do
    context "and there is no slots running" do
      it "stops to accept new tasks" do
        expect { subject.perform }
          .to change(node, :accept_new_tasks).from(true).to(false)
      end

      it "deletes the node" do
        expect { subject.perform }
        .to change { Node.find(node.id) }.from(node).to(nil)
      end

      it "does not raises error" do
        expect { subject.perform }.to_not raise_error
      end
    end

    context "and there are slots running" do
      before do
        Fabricate(:slot_running, node: node)
      end

      it "does not delete the node" do
        expect do
          subject.perform rescue nil
        end.to_not change { Node.find(node.id) }
      end

      it "raises an error" do
        expect { subject.perform }.to raise_error(described_class::NodeWithRunningSlotsError)
      end
    end
  end
end
