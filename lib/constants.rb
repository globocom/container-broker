# frozen_string_literal: true

module Constants
  class ExecutionType
    FORMAT = /\A([a-z0-9])+(\-[a-z0-9]+)*\z/.freeze
    INVALID_FORMAT_MESSAGE = "only allows lowercase letters, numbers and hyphen symbol"
  end
end
