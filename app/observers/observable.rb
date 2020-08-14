# frozen_string_literal: true

module Observable
  mattr_accessor :observers

  def self.extended(model)
    model.observers = Set.new
  end

  def add_observer(observer)
    observers << observer
  end

  def observer_instances_for(model)
    observers.map do |observer|
      observer.new(model)
    end
  end
end
