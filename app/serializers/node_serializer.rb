# frozen_string_literal: true

class NodeSerializer < ActiveModel::Serializer
  attributes :uuid, :hostname, :status, :accept_new_tasks, :slots_execution_types, :runner, :runner_capacity_reached
end
