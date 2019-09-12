# frozen_string_literal: true

class StatusPanelTaskSerializer < ActiveModel::Serializer
  attributes :uuid, :name, :image, :cmd, :status, :exit_code, :error, :try_count, :created_at,
             :started_at, :finished_at, :progress, :seconds_running, :tags, :container_id, :storage_mount,
             :slot, :execution_type

  def slot
    if object.slot
      {
        uuid: object.slot.uuid,
        name: object.slot.name
      }
    end
  end
end
