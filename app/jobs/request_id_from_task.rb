# frozen_string_literal: true

module RequestIdFromTask
  def request_id_from_args(args)
    args[:task]&.request_id
  end
end
