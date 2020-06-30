# frozen_string_literal: true

class RedisUrlParser
  def self.call(uri)
    return { url: uri } unless uri.start_with?("sentinel")

    m = uri.match("sentinel://:([^@]*)@([^/]*)/service_name:(.*)")
    password = m[1]
    sentinel_uris = m[2]
    name = m[3]
    url = "redis://:#{password}@#{name}"
    sentinels = sentinel_uris.split(",").map do |sentinel_uri|
      host, port = sentinel_uri.split(":")
      {
        host: host,
        port: port
      }
    end

    {
      url: url,
      sentinels: sentinels
    }
  end
end
