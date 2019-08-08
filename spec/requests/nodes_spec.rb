require 'rails_helper'

RSpec.describe "Nodes", type: :request do
  describe "POST /node" do
    let(:params) do
      {
        node: {
          hostname: "host1.test",
          slots_execution_types: {
            cpu: 1,
            network: 3
          }
        }
      }
    end

    it "creates a new node" do
      post nodes_path, params: params
      expect(response).to be_created
    end

    it "returns the newly created node" do
      post nodes_path, params: params

      expect(json_response).to include_json(hostname: "host1.test")
      expect(json_response).to match(hash_including("uuid"))
      expect(json_response).to match(hash_including(
        "slots_execution_types" => {
          "cpu" => "1",
          "network" => "3"
        }
      ))
    end
  end

  describe "GET /nodes" do
    let!(:node1) { Fabricate(:node, hostname: "node1.test") }
    let!(:node2) { Fabricate(:node, hostname: "node2.test") }

    it "gets all nodes" do
      get nodes_path

      expect(json_response).to match_array(
        [
          hash_including("uuid" => node1.uuid, "hostname" => node1.hostname),
          hash_including("uuid" => node2.uuid, "hostname" => node2.hostname)
        ]
      )
    end
  end

  describe "PATCH /nodes/:uuid" do
    let!(:node) { Fabricate(:node, hostname: "node1.test") }
    let(:new_hostname) { "node2.test" }
    let(:new_slots_execution_type) { { "cpu" => "3", "network" => "8" } }

    it "returns ok" do
      patch node_path(node.uuid), params: {node: {hostname: new_hostname}}

      expect(response).to be_ok
    end

    it "updates the slots_execution_types" do
      patch node_path(node.uuid), params: {node: {hostname: new_hostname, slots_execution_types: new_slots_execution_type}}

      node.reload
      expect(node.slots_execution_types).to eq(new_slots_execution_type)
    end

    it "does not update the hostname" do
      expect do
        patch node_path(node.uuid), params: {node: {hostname: new_hostname}, slots_execution_types: new_slots_execution_type}
        node.reload
      end.to_not change(node, :hostname)
    end
  end

  describe "DELETE /nodes/:uuid" do
    let!(:node) { Fabricate(:node, hostname: "node1.test") }

    context "when node is working" do
      before { Fabricate(:slot_running, node: node) }

      it "returns error" do
        delete node_path(node.uuid)

        expect(response.status).to eq(406)
      end

      it "does not remove the node" do
        expect { delete node_path(node.uuid) }
          .to_not change(Node, :count)
      end
    end

    context "when node is idle" do
      it "returns ok" do
        delete node_path(node.uuid)

        expect(response).to be_ok
      end

      it "removes the node" do
        expect { delete node_path(node.uuid) }
          .to change(Node, :count).by(-1)
      end
    end
  end

  context "POST /nodes/:uuid/accept_new_tasks" do
    let!(:node) { Fabricate(:node, accept_new_tasks: false) }

    subject { post accept_new_tasks_node_path(node.uuid); node.reload }

    it "gets paused" do
      expect { subject }.to change(node, :accept_new_tasks?).from(false).to(true)
    end
  end

  context "POST /nodes/:uuid/reject_new_tasks" do
    let!(:node) { Fabricate(:node, accept_new_tasks: true) }

    subject { post reject_new_tasks_node_path(node.uuid); node.reload }

    it "gets paused" do
      expect { subject }.to change(node, :accept_new_tasks?).from(true).to(false)
    end
  end

  context "POST /nodes/:uuid/kill_containers" do
    let!(:node) { Fabricate(:node, accept_new_tasks: true) }

    let(:kill_containers_service) { double("KillNodeContainers") }

    before do
      allow(KillNodeContainers).to receive(:new).with(node: node).and_return(kill_containers_service)
    end

    it "kills all node containers" do
      expect(kill_containers_service).to receive(:perform)

      post kill_containers_node_path(node.uuid)
    end
  end

  describe "GET /nodes/healthcheck" do
    describe "and all nodes are available" do
      let!(:node1) { Fabricate(:node, hostname: "node1.test")}
      let!(:node2) { Fabricate(:node, hostname: "node2.test")}

      it "gets working status" do
        get healthcheck_nodes_path

        expect(json_response).to eq(
          "status" => "WORKING",
          "failed_nodes" => []
        )
      end
    end

    describe "and there are unavailable nodes" do
      let!(:node1) { Fabricate(:node, hostname: "node1.test", status: "unavailable")}
      let!(:node2) { Fabricate(:node, hostname: "node2.test")}

      it "gets failing status" do
        get healthcheck_nodes_path

        expect(json_response).to match(hash_including(
          "status" => "FAILING",
          "failed_nodes" => [
            hash_including("uuid" => node1.uuid)
          ]
        ))
      end
    end

    describe "and there are unstable nodes" do
      let!(:node1) { Fabricate(:node, hostname: "node1.test", status: "unstable")}
      let!(:node2) { Fabricate(:node, hostname: "node2.test")}

      it "gets failing status" do
        get healthcheck_nodes_path

        expect(json_response).to eq(
          "status" => "WORKING",
          "failed_nodes" => []
        )
      end
    end
  end
end
