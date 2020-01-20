# frozen_string_literal: true

class KubernetesClient
  attr_reader :uri, :bearer_token

  def initialize(uri:, bearer_token:)
    @uri = uri
    @bearer_token = bearer_token
  end

  # rubocop:disable Metrics/ParameterLists
  def create_job(job_name:, namespace:, image:, cmd:, internal_mounts: [], external_mounts: [], node_selector:)
    job = Kubeclient::Resource.new(
      metadata: {
        name: job_name,
        namespace: namespace
      },
      spec: {
        backoffLimit: 2,
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

  def batch_client
    Kubeclient::Client.new(build_client_uri(path: "/apis/batch"), "v1", auth_options: { bearer_token: bearer_token })
  end

  def build_client_uri(path:)
    parsed_uri = URI.parse(uri)
    URI::Generic.build(host: parsed_uri.host, scheme: parsed_uri.scheme, path: path).to_s
  end
end
