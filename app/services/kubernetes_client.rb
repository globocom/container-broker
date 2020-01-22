# frozen_string_literal: true

class KubernetesClient
  class PodNotFoundError < StandardError; end

  attr_reader :uri, :bearer_token, :namespace

  def initialize(uri:, bearer_token:, namespace:)
    @uri = uri
    @bearer_token = bearer_token
    @namespace = namespace
  end

  def api_info
    pod_client.api
  end

  # rubocop:disable Metrics/ParameterLists
  def create_job(job_name:, image:, cmd:, internal_mounts: [], external_mounts: [], node_selector:)
    job = Kubeclient::Resource.new(
      metadata: {
        name: job_name,
        namespace: namespace
      },
      spec: {
        backoffLimit: 0,
        template: {
          spec: {
            containers: [
              {
                name: job_name,
                image: image,
                command: ["sh", "-c", cmd],
                resources: {
                  requests: { cpu: 1 }
                },
                volumeMounts: internal_mounts
              }
            ],
            restartPolicy: "Never",
            nodeSelector: { node_selector => "" },
            tolerations: [
              {
                key: node_selector,
                effect: "NoSchedule"
              }
            ],
            volumes: external_mounts
          }
        }
      }
    )

    batch_client.create_job(job)

    job_name
  end
  # rubocop:enable Metrics/ParameterLists

  def fetch_job_logs(job_name:)
    pod_client.get_pod_log(fetch_pod_name(job_name: job_name), namespace)
  end

  def fetch_pod(job_name:)
    pod_client.get_pod(fetch_pod_name(job_name: job_name), namespace)
  end

  def fetch_jobs_status
    batch_client
      .get_jobs(namespace: namespace)
      .each_with_object({}) do |job, result|
        result[job.metadata.name] = job.status
      end
  end

  private

  def fetch_pod_name(job_name:)
    job_pod_name = pod_client.get_pods(namespace: namespace, label_selector: "job-name=#{job_name}").first&.metadata&.name

    raise PodNotFoundError, "Pod not found for job #{job_name}" unless job_pod_name

    job_pod_name
  end

  def batch_client
    Kubeclient::Client.new(build_client_uri(path: "/apis/batch"), "v1", auth_options: { bearer_token: bearer_token })
  end

  def pod_client
    Kubeclient::Client.new(build_client_uri(path: "/api"), "v1", auth_options: { bearer_token: bearer_token })
  end

  def build_client_uri(path:)
    parsed_uri = URI.parse(uri)
    URI::Generic.build(host: parsed_uri.host, scheme: parsed_uri.scheme, path: path).to_s
  end
end
