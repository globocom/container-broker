# frozen_string_literal: true

require "rails_helper"

RSpec.describe Observable do
  subject { observable_class.new }
  let(:observable_class) do
    Class.new do
      extend Observable
    end
  end
  let(:observer_class) { double }
  let(:observer) { double }

  before { allow(observer_class).to receive(:new).with(subject).and_return(observer) }
  after { observable_class.remove_observer(observer_class) }

  it "accepts observers" do
    observable_class.add_observer(observer_class)

    expect(observable_class.observers).to include(observer_class)
  end

  it "removes observers" do
    observable_class.add_observer(observer_class)
    observable_class.remove_observer(observer_class)

    expect(observable_class.observers).to_not include(observer_class)
  end

  it "creates observer instances" do
    observable_class.add_observer(observer_class)

    expect(observable_class.observer_instances_for(subject)).to include(observer)
  end
end
