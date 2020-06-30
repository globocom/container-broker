# frozen_string_literal: true

module IdempotentRequest
  class Policy
    attr_reader :request

    def initialize(request)
      @request = request
    end

    def should?
      !request.request.get?
    end
  end
end
