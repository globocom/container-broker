# frozen_string_literal: true

class TaskTag
  include Mongoid::Document
  include Mongoid::Uuid

  field :name, type: String
  field :values, type: Array, default: []

  index({ name: 1 }, unique: true)
end
