# frozen_string_literal: true

require "rails_helper"
RSpec.describe KubernetesClient do
  subject(:kubernetes_client) { described_class.new(uri: uri, bearer_token: bearer_token) }
  let(:kubeclient) { double(Kubeclient::Client, create_job: nil) }

  let(:uri) { "https://cloud.test" }
  let(:bearer_token) { SecureRandom.base64 }
  let(:namespace) { "my-namespace" }
  let(:node_selector) { "node-role.kubernetes.io/ef" }

  before do
    allow(Kubeclient::Client).to receive(:new).and_return(kubeclient)
  end

  context "creating jobs" do
    let(:job_name) { "create-folder-123" }
    let(:image) { "busybox" }
    let(:cmd) { "ls" }
    let(:internal_mounts) do
      {
        name: "nfs-ef",
        mountPath: "/tmp/ef-shared"
      }
    end
    let(:external_mounts) do
      {
        name: "nfs-ef",
        nfs: {
          server: "efactory.cmfdnc01",
          path: "/dev/project"
        }
      }
    end
    let(:resource) { Kubeclient::Resource.new }

    before do
      allow(Kubeclient::Resource).to receive(:new).and_return(resource)
    end

    def create_job
      kubernetes_client.create_job(
        job_name: job_name,
        namespace: namespace,
        image: image,
        cmd: cmd,
        internal_mounts: internal_mounts,
        external_mounts: external_mounts,
        node_selector: node_selector
      )
    end

    it "authenticates in the cluster using the provided token" do
      expect(Kubeclient::Client).to receive(:new).with("https://cloud.test/apis/batch", "v1", auth_options: { bearer_token: bearer_token })

      create_job
    end

    it "creates the resource" do
      expect(Kubeclient::Resource).to receive(:new).with(
        metadata: {
          name: "create-folder-123", namespace: "my-namespace"
        },
        spec: {
          backoffLimit: 2,
          template: {
            spec:
            {
              containers: [
                {
                  name: "create-folder-123",
                  image: "busybox",
                  command: ["sh", "-c", "ls"],
                  resources: {
                    requests: {
                      cpu: 1
                    }
                  },
                  volumeMounts: {
                    name: "nfs-ef",
                    mountPath: "/tmp/ef-shared"
                  }
                }
              ],
              restartPolicy: "Never",
              nodeSelector: {
                "node-role.kubernetes.io/ef" => ""

              },
              tolerations: [
                {
                  key: "node-role.kubernetes.io/ef",
                  effect: "NoSchedule"
                }
              ],
              volumes: {
                name: "nfs-ef",
                nfs: {
                  server: "efactory.cmfdnc01",
                  path: "/dev/project"
                }
              }
            }
          }
        }
      )

      create_job
    end

    it "creates the job in kubernetes cluster using the created resource" do
      expect(kubeclient).to receive(:create_job).with(resource)

      create_job
    end
  end
end
