# frozen_string_literal: true

require "rails_helper"
RSpec.describe KubernetesClient do
  subject(:kubernetes_client) { described_class.new(uri: uri, bearer_token: bearer_token, namespace: namespace) }
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
          backoffLimit: 0,
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

  context "getting jobs statuses" do
    let(:job_name) { "create-folder-12345" }
    let(:job_list) do
      [
        Kubeclient::Resource.new(metadata: { name: "job1" }, status: { startTime: Time.zone.now - 2, completionTime: Time.zone.now - 1, succeeded: 1 }),
        Kubeclient::Resource.new(metadata: { name: "job2" }, status: { startTime: Time.zone.now - 2, completionTime: Time.zone.now - 1, succeeded: 1 }),
        Kubeclient::Resource.new(metadata: { name: "job3" }, status: { startTime: Time.zone.now - 2, failed: 3 })
      ]
    end

    before do
      allow(subject.batch_client).to receive(:get_jobs).and_return(job_list)
    end

    it "gets all jobs status" do
      expect(subject.fetch_jobs_status).to match(
        "job1" => have_attributes(startTime: be_a(Time), completionTime: be_a(Time), succeeded: 1),
        "job2" => have_attributes(startTime: be_a(Time), completionTime: be_a(Time), succeeded: 1),
        "job3" => have_attributes(startTime: be_a(Time), failed: 3)
      )
    end
  end

  context "getting job logs" do
    let(:job_name) { "create-folder-12345" }
    let(:pod_name) { "#{job_name}-xyz1" }
    let(:log) { "Logs here" }
    let(:pod_list) do
      [
        Kubeclient::Resource.new(metadata: { name: pod_name })
      ]
    end
    before do
      allow(subject.pod_client).to receive(:get_pods).with(namespace: namespace, label_selector: "job-name=#{job_name}").and_return(pod_list)
      allow(subject.pod_client).to receive(:get_pod_log).with(pod_name, namespace).and_return(log)
    end

    it "gets the pod associated with the job" do
      expect(subject.send(:pod_client)).to receive(:get_pods).with(namespace: namespace, label_selector: "job-name=#{job_name}").and_return(pod_list)

      subject.fetch_job_logs(job_name: job_name)
    end

    it "returns the log" do
      expect(subject.fetch_job_logs(job_name: job_name)).to eq(log)
    end
  end
end
