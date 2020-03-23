# frozen_string_literal: true

require "rails_helper"
RSpec.describe KubernetesClient do
  subject(:kubernetes_client) { described_class.new(uri: uri, bearer_token: bearer_token, namespace: namespace) }
  let(:pod_client) { double(Kubeclient::Client, create_pod: nil) }

  let(:uri) { "https://cloud.test" }
  let(:bearer_token) { SecureRandom.base64 }
  let(:namespace) { "my-namespace" }
  let(:node_selector) { "node-role.kubernetes.io/ef" }

  before do
    allow(Kubeclient::Client).to receive(:new)
      .with("https://cloud.test:443/api", "v1", auth_options: { bearer_token: bearer_token }, ssl_options: { verify_ssl: false })
      .and_return(pod_client)
  end

  context "creating pods" do
    let(:pod_name) { "create-folder-123" }
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
      allow(Settings.kubernetes).to receive(:requests).and_return(OpenStruct.new(cpu: 1, memory: 2))
      allow(Settings.kubernetes).to receive(:limits).and_return(OpenStruct.new(cpu: 3, memory: 4))
    end

    def create_pod
      kubernetes_client.create_pod(
        pod_name: pod_name,
        image: image,
        cmd: cmd,
        internal_mounts: internal_mounts,
        external_mounts: external_mounts,
        node_selector: node_selector
      )
    end

    it "authenticates in the cluster using the provided token" do
      expect(Kubeclient::Client).to receive(:new)
        .with("https://cloud.test:443/api", "v1", auth_options: { bearer_token: bearer_token }, ssl_options: { verify_ssl: false })
        .and_return(pod_client)

      create_pod
    end

    it "creates the resource" do
      expect(Kubeclient::Resource).to receive(:new).with(
        metadata: {
          name: "create-folder-123",
          namespace: "my-namespace"
        },
        spec: {
          containers: [
            {
              name: "create-folder-123",
              image: "busybox",
              command: ["sh", "-c", "ls"],
              resources: {
                requests: {
                  cpu: 1,
                  memory: 2
                },
                limits: {
                  cpu: 3,
                  memory: 4
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
      )

      create_pod
    end

    it "creates the pod in kubernetes cluster using the created resource" do
      expect(pod_client).to receive(:create_pod).with(resource)

      create_pod
    end
  end

  context "getting pod" do
    let(:pod_name) { "create-folder-12345-xyz1" }
    let(:pod) { Kubeclient::Resource.new(kind: "Pod") }

    before do
      allow(pod_client).to receive(:get_pod)
        .with(pod_name, namespace)
        .and_return(pod)
    end

    context "when pod exists" do
      let(:pod_list) do
        [
          Kubeclient::Resource.new(metadata: { name: pod_name })
        ]
      end

      it "returns the pod" do
        expect(subject.fetch_pod(pod_name: pod_name)).to eq(pod)
      end
    end

    context "when the pod does not exist" do
      let(:pod_list) { [] }

      before do
        allow(pod_client).to receive(:get_pod)
          .with(pod_name, namespace)
          .and_raise(Kubeclient::ResourceNotFoundError.new(404, "Not found", nil))
      end

      it "raises an error" do
        expect { subject.fetch_pod(pod_name: pod_name) }
          .to raise_error(described_class::PodNotFoundError, "Pod not found #{pod_name}")
      end
    end
  end

  context "getting pods statuses" do
    let(:pod_list) do
      [
        Kubeclient::Resource.new(
          metadata: {
            name: "pod1"
          },
          status: {
            containerStatuses: [
              {
                state: {
                  terminated: {
                    exitCode: 0,
                    reason: "Completed",
                    startedAt: "2020-01-21T21:20:32Z",
                    finishedAt: "2020-01-21T21:20:32Z",
                    containerID: "docker://f2057c90849270e2e9991fcb6916f5200998ab6cfed08f6b14d905adc8ae366b"
                  }
                }
              }
            ]
          }
        ),
        Kubeclient::Resource.new(
          metadata: {
            name: "pod2"
          },
          status: {
            containerStatuses: [
              {
                state: {
                  waiting: {
                    reason: "ImagePullBackOff",
                    message: "Back-off pulling image buxyboxxx"
                  }
                }
              }
            ]
          }
        ),
        Kubeclient::Resource.new(
          metadata: {
            name: "pod3"
          },
          status: {
            containerStatuses: [
              {
                state: {
                  running: {
                    startedAt: "2020-01-20T21:20:32Z"
                  }
                }
              }
            ]
          }
        )
      ]
    end

    before do
      allow(pod_client).to receive(:get_pods).and_return(pod_list)
    end

    it "gets all pods status grouped by pod name" do
      expect(subject.fetch_pods).to match(
        "pod1" => have_attributes(
          status: have_attributes(
            containerStatuses: [
              have_attributes(
                state: have_attributes(
                  terminated: have_attributes(
                    reason: "Completed"
                  )
                )
              )
            ]
          )
        ),
        "pod2" => have_attributes(
          status: have_attributes(
            containerStatuses: [
              have_attributes(
                state: have_attributes(
                  waiting: have_attributes(
                    reason: "ImagePullBackOff",
                    message: "Back-off pulling image buxyboxxx"
                  )
                )
              )
            ]
          )
        ),
        "pod3" => have_attributes(
          status: have_attributes(
            containerStatuses: [
              have_attributes(
                state: have_attributes(
                  running: have_attributes(
                    startedAt: "2020-01-20T21:20:32Z"
                  )
                )
              )
            ]
          )
        )
      )
    end
  end

  context "getting pod logs" do
    let(:pod_name) { "command" }
    let(:logs) { "Logs here" }
    let(:response) { double(body: logs) }

    context "when pod exists" do
      before do
        allow(pod_client).to receive(:get_pod_log)
          .with(pod_name, namespace)
          .and_return(response)
      end

      it "returns the log" do
        expect(subject.fetch_pod_logs(pod_name: pod_name)).to eq(logs)
      end
    end

    context "when the pod does not exist" do
      before do
        allow(pod_client).to receive(:get_pod_log)
          .with(pod_name, namespace)
          .and_raise(Kubeclient::ResourceNotFoundError.new(404, "Not Found", nil))
      end

      it "raises an error" do
        expect { subject.fetch_pod_logs(pod_name: pod_name) }
          .to raise_error(described_class::PodNotFoundError, "Pod not found #{pod_name}")
      end
    end

    context "when the pod logs does not exist" do
      before do
        allow(pod_client).to receive(:get_pod_log)
          .with(pod_name, namespace)
          .and_raise(Kubeclient::HttpError.new(400, "No logs", nil))
      end

      it "raises LogsNotFoundError" do
        expect { subject.fetch_pod_logs(pod_name: pod_name) }
          .to raise_error(described_class::LogsNotFoundError)
      end
    end
  end

  context "getting the cluster availability" do
    context "when api is valid" do
      before do
        allow(pod_client).to receive(:api).and_return(
          "kind" => "APIVersions",
          "versions" => ["v1"],
          "serverAddressByClientCIDRs" => [
            {
              "clientCIDR" => "0.0.0.0/0",
              "serverAddress" => "10.224.139.13:443"
            }
          ]
        )
      end

      it "returns an hash" do
        expect(subject.api_info).to be_a(Hash)
      end
    end

    context "when api is not valid" do
      before { allow(pod_client).to receive(:api).and_raise(SocketError) }

      it "raises the error" do
        expect { subject.api_info }.to raise_error(KubernetesClient::NetworkError)
      end
    end
  end

  context "deleting pod" do
    let(:pod_name) { "command-xyz1" }
    let(:delete_options) { double(Kubeclient::Resource) }

    before do
      allow(Kubeclient::Resource).to receive(:new).and_call_original
      allow(Kubeclient::Resource).to receive(:new)
        .with(apiVersion: "v1", gracePeriodSeconds: 0, kind: "DeleteOptions")
        .and_return(delete_options)
    end

    context "when pod exists" do
      it "deletes pod" do
        expect(pod_client).to receive(:delete_pod).with(pod_name, namespace, delete_options: delete_options)

        subject.force_delete_pod(pod_name: pod_name)
      end
    end

    context "when the pod does not exist" do
      before do
        allow(pod_client).to receive(:delete_pod)
          .with(pod_name, namespace, delete_options: delete_options)
          .and_raise(Kubeclient::ResourceNotFoundError.new(404, "Not found", nil))
      end

      it "raises an error" do
        expect { subject.force_delete_pod(pod_name: pod_name) }
          .to raise_error(described_class::PodNotFoundError, "Pod not found #{pod_name}")
      end
    end
  end
end
