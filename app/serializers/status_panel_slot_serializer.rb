# frozen_string_literal: true

class StatusPanelSlotSerializer < ActiveModel::Serializer
  attributes :uuid, :name, :runner_id, :status, :execution_type
end
