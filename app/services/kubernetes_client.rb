# frozen_string_literal: true

class KubernetesClient
  class PodNotFoundError < StandardError; end
  class NetworkError < StandardError; end
  class LogsNotFoundError < StandardError; end

  LOG_UNAVAILABLE_HTTP_ERROR = 400

  attr_reader :uri, :bearer_token, :namespace

  def initialize(uri:, bearer_token:, namespace:)
    @uri = uri
    @bearer_token = bearer_token
    @namespace = namespace
  end

  def api_info
    handle_exception { pod_client.api }
  end

  # rubocop:disable Metrics/ParameterLists
  def create_pod(pod_name:, image:, cmd:, internal_mounts: [], external_mounts: [], node_selector:)
    handle_exception do
      pod = Kubeclient::Resource.new(
        metadata: {
          name: pod_name,
          namespace: namespace
        },
        spec: {
          containers: [
            {
              name: pod_name,
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
      )

      pod_client.create_pod(pod)

      pod_name
    end
  end
  # rubocop:enable Metrics/ParameterLists

  def fetch_pod_logs(pod_name:)
    handle_exception(pod_name) do
      pod_client.get_pod_log(pod_name, namespace).body
    rescue Kubeclient::HttpError => e
      raise LogsNotFoundError if e.error_code == LOG_UNAVAILABLE_HTTP_ERROR

      raise
    end
  end

  def fetch_pod(pod_name:)
    handle_exception(pod_name) { pod_client.get_pod(pod_name, namespace) }
  end

  def force_delete_pod(pod_name:)
    handle_exception(pod_name) { pod_client.delete_pod(pod_name, namespace, delete_options: delete_options) }
  end

  def fetch_pods
    handle_exception do
      pod_client
        .get_pods(namespace: namespace)
        .each_with_object({}) do |pod, result|
          result[pod.metadata.name] = pod
        end
    end
  end

  def handle_exception(pod_name = nil)
    yield
  rescue Kubeclient::ResourceNotFoundError
    raise PodNotFoundError, "Pod not found #{pod_name}"
  rescue Kubeclient::HttpError, SocketError, Errno::ECONNREFUSED, OpenSSL::SSL::SSLError => e
    raise NetworkError, "#{e.class}: #{e.message}"
  end

  private

  def delete_options
    Kubeclient::Resource.new(
      apiVersion: "v1",
      gracePeriodSeconds: 0,
      kind: "DeleteOptions"
    )
  end

  def pod_client
    Kubeclient::Client.new(build_client_uri(path: "/api"), "v1", auth_options: { bearer_token: bearer_token }, ssl_options: { verify_ssl: false })
  end

  def build_client_uri(path:)
    parsed_uri = URI.parse(uri)
    URI::Generic.build(host: parsed_uri.host, port: parsed_uri.port, scheme: parsed_uri.scheme, path: path).to_s
  end
end
