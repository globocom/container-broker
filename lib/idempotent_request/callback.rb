# frozen_string_literal: true

module IdempotentRequest
  class Callback
    attr_reader :request

    def initialize(request)
      @request = request
    end

    def detected(key:)
      Rails.logger.warn "IdempotentRequest request detected, #{message_params(key: key)}"
    end

    def message_params(key:)
      {
        key: key,
        method: request.request.request_method,
        path: request.request.path_info
      }
        .map { |k, v| "#{k}: #{v}" }
        .join(", ")
    end
  end
end
