# frozen_string_literal: true

module Constants
  class ExecutionType
    REGEX = /\A([a-z0-9])+(\-[a-z0-9]+)*\z/.freeze
    MESSAGE = "only allows lowercase letters, numbers and hyphen symbol"
  end
end
