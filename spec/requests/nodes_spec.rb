# frozen_string_literal: true

require "rails_helper"

RSpec.describe "Nodes", type: :request do
  describe "POST /node" do
    context "when valid params" do
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
        post "/nodes", params: params
        expect(response).to be_created
      end

      it "returns the newly created node" do
        post "/nodes", params: params

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

    context "when invalid params" do
      let(:params) do
        {
          node: {
            hostname: "host1.test",
            slots_execution_types: {
              cpu_: 1
            }
          }
        }
      end

      it "returns error" do
        post "/nodes", params: params

        expect(response).to be_unprocessable
      end

      it "returns error message" do
        post "/nodes", params: params

        expect(json_response).to eq(
          "slots_execution_types" => ["only allows lowercase letters, numbers and hyphen symbol"]
        )
      end
    end
  end

  describe "GET /nodes" do
    let!(:node1) { Fabricate(:node, hostname: "node1.test") }
    let!(:node2) { Fabricate(:node, hostname: "node2.test") }

    it "gets all nodes" do
      get "/nodes"

      expect(json_response).to match_array(
        [
          hash_including("uuid" => node1.uuid, "hostname" => node1.hostname),
          hash_including("uuid" => node2.uuid, "hostname" => node2.hostname)
        ]
      )
    end
  end

  describe "GET /node/:uuid" do
    let!(:node1) { Fabricate(:node, hostname: "node1.test") }

    it "gets a node" do
      get "/nodes/#{node1.uuid}"
      expect(json_response).to include(
        "uuid" => node1.uuid,
        "hostname" => node1.hostname,
        "accept_new_tasks" => node1.accept_new_tasks,
        "status" => node1.status,
        "slots_execution_types" => hash_including(
          "io" => 10,
          "cpu" => 5
        )
      )
    end

    it "raise an error" do
      expect { get "/nodes/WRONG" }.to raise_error(Mongoid::Errors::DocumentNotFound)
    end
  end

  describe "PATCH /nodes/:uuid" do
    let!(:node) { Fabricate(:node, hostname: "node1.test") }
    context "when valid params" do
      let(:new_hostname) { "node2.test" }
      let(:new_slots_execution_type) { { "cpu" => "3", "network" => "8" } }

      it "returns ok" do
        patch "/nodes/#{node.uuid}", params: { node: { hostname: new_hostname } }

        expect(response).to be_ok
      end

      it "updates the slots_execution_types" do
        patch "/nodes/#{node.uuid}", params: { node: { hostname: new_hostname, slots_execution_types: new_slots_execution_type } }

        node.reload
        expect(node.slots_execution_types).to eq(new_slots_execution_type)
      end

      it "does not update the hostname" do
        expect do
          patch "/nodes/#{node.uuid}", params: { node: { hostname: new_hostname }, slots_execution_types: new_slots_execution_type }
          node.reload
        end.to_not change(node, :hostname)
      end
    end

    context "when invalid params" do
      let(:new_slots_execution_type) { { "cpu" => "3", "network_" => "8" } }

      it "returns error" do
        patch "/nodes/#{node.uuid}", params: { node: { slots_execution_types: new_slots_execution_type } }

        expect(response).to be_unprocessable
      end

      it "returns error message" do
        patch "/nodes/#{node.uuid}", params: { node: { slots_execution_types: new_slots_execution_type } }

        expect(json_response).to eq(
          "slots_execution_types" => ["only allows lowercase letters, numbers and hyphen symbol"]
        )
      end
    end
  end

  describe "DELETE /nodes/:uuid" do
    let!(:node) { Fabricate(:node, hostname: "node1.test") }

    context "when node is working" do
      before { Fabricate(:slot_running, node: node) }

      it "returns error" do
        delete "/nodes/#{node.uuid}"

        expect(response.status).to eq(406)
      end

      it "does not remove the node" do
        expect { delete "/nodes/#{node.uuid}" }
          .to_not change(Node, :count)
      end
    end

    context "when node is idle" do
      it "returns ok" do
        delete "/nodes/#{node.uuid}"

        expect(response).to be_ok
      end

      it "removes the node" do
        expect { delete "/nodes/#{node.uuid}" }
          .to change(Node, :count).by(-1)
      end
    end
  end

  context "POST /nodes/:uuid/accept_new_tasks" do
    let!(:node) { Fabricate(:node, accept_new_tasks: false) }

    subject { post "/nodes/#{node.uuid}/accept_new_tasks"; node.reload }

    it "gets paused" do
      expect { subject }.to change(node, :accept_new_tasks?).from(false).to(true)
    end
  end

  context "POST /nodes/:uuid/reject_new_tasks" do
    let!(:node) { Fabricate(:node, accept_new_tasks: true) }

    subject { post "/nodes/#{node.uuid}/reject_new_tasks"; node.reload }

    it "gets paused" do
      expect { subject }.to change(node, :accept_new_tasks?).from(true).to(false)
    end
  end

  context "POST /nodes/:uuid/kill_containers" do
    let!(:node) { Fabricate(:node, accept_new_tasks: true) }

    let(:kill_containers_service) { double("KillNodeRunners") }

    before do
      allow(KillNodeRunners).to receive(:new).with(node: node).and_return(kill_containers_service)
    end

    it "kills all node containers" do
      expect(kill_containers_service).to receive(:perform)

      post "/nodes/#{node.uuid}/kill_containers"
    end
  end

  describe "GET /nodes/healthcheck" do
    describe "and all nodes are available" do
      let!(:node1) { Fabricate(:node, hostname: "node1.test") }
      let!(:node2) { Fabricate(:node, hostname: "node2.test") }

      it "gets working status" do
        get "/nodes/healthcheck"

        expect(json_response).to eq(
          "status" => "WORKING",
          "failed_nodes" => []
        )
      end
    end

    describe "and there are unavailable nodes" do
      let!(:node1) { Fabricate(:node, hostname: "node1.test", status: "unavailable") }
      let!(:node2) { Fabricate(:node, hostname: "node2.test") }

      it "gets failing status" do
        get "/nodes/healthcheck"

        expect(json_response).to match(hash_including(
                                         "status" => "FAILING",
                                         "failed_nodes" => [
                                           hash_including("uuid" => node1.uuid)
                                         ]
                                       ))
      end
    end

    describe "and there are unstable nodes" do
      let!(:node1) { Fabricate(:node, hostname: "node1.test", status: "unstable") }
      let!(:node2) { Fabricate(:node, hostname: "node2.test") }

      it "gets failing status" do
        get "/nodes/healthcheck"

        expect(json_response).to eq(
          "status" => "WORKING",
          "failed_nodes" => []
        )
      end
    end
  end
end
