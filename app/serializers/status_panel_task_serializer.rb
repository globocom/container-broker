# frozen_string_literal: true

class StatusPanelTaskSerializer < ActiveModel::Serializer
  attributes :uuid, :name, :image, :cmd, :status, :exit_code, :error, :try_count, :created_at,
             :started_at, :finished_at, :progress, :seconds_running, :tags, :runner_id,
             :storage_mounts, :slot, :execution_type

  def slot
    if object.slot
      {
        uuid: object.slot.uuid,
        name: object.slot.name
      }
    end
  end
end
