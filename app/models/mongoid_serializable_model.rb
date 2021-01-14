# frozen_string_literal: true

class MongoidSerializableModel
  attr_reader :model

  include GlobalID::Identification

  def initialize(model)
    @model = model
  end

  def to_global_id
    model.to_global_id
  end
end
