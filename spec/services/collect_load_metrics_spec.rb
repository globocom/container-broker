# frozen_string_literal: true

require "rails_helper"

RSpec.describe CollectLoadMetrics, type: :service do
  let(:tasks_metrics_instance) { instance_double(Metrics) }
  let(:slots_metrics_instance) { instance_double(Metrics) }
  let(:slots_usage_percent_instance) { instance_double(Metrics) }

  before do
    allow(Metrics).to receive(:new).with("tasks_count").and_return(tasks_metrics_instance)
    allow(Metrics).to receive(:new).with("slots_count").and_return(slots_metrics_instance)
    allow(Metrics).to receive(:new).with("slots_usage_percent").and_return(slots_usage_percent_instance)

    allow(tasks_metrics_instance).to receive(:count)
    allow(slots_metrics_instance).to receive(:count)
    allow(slots_usage_percent_instance).to receive(:count)
  end

  context "when to send slots count metrics" do
    before do
      Fabricate(:slot, status: :available, execution_type: "cpu")
      Fabricate(:slot, status: :available, execution_type: "cpu")
      Fabricate(:slot, status: :available, execution_type: "io")
      Fabricate(:slot, status: :running, execution_type: "network")
      Fabricate(:slot, status: :available, execution_type: "extra", node: Fabricate(:node_unstable))
    end

    it "sends for cpu execution type and available status" do
      expect(slots_metrics_instance).to receive(:count).with(execution_type: "cpu", status: "available", amount: 2)

      subject.perform
    end

    it "sends for io execution type and available status" do
      expect(slots_metrics_instance).to receive(:count).with(execution_type: "io", status: "available", amount: 1)

      subject.perform
    end

    it "sends for network execution type and running status" do
      expect(slots_metrics_instance).to receive(:count).with(execution_type: "network", status: "running", amount: 1)

      subject.perform
    end

    it "does not send to node unstable" do
      expect(slots_metrics_instance).to_not receive(:count).with(execution_type: "extra", status: "available", amount: 1)

      subject.perform
    end
  end

  context "when to send tasks count metrics" do
    before do
      Fabricate(:task, status: :waiting, execution_type: "cpu")
      Fabricate(:task, status: :waiting, execution_type: "cpu")
      Fabricate(:task, status: :waiting, execution_type: "io")
      Fabricate(:task, status: :started, execution_type: "cpu")
    end

    it "sends for cpu execution type and waiting status" do
      expect(tasks_metrics_instance).to receive(:count).with(execution_type: "cpu", status: "waiting", amount: 2)

      subject.perform
    end

    it "sends for cpu execution type and waiting status" do
      expect(tasks_metrics_instance).to receive(:count).with(execution_type: "io", status: "waiting", amount: 1)

      subject.perform
    end

    it "sends for cpu execution type and started status" do
      expect(tasks_metrics_instance).to receive(:count).with(execution_type: "cpu", status: "started", amount: 1)

      subject.perform
    end
  end

  context "when to send slots usage percent" do
    before do
      Fabricate(:slot, status: :available, execution_type: "cpu")
      Fabricate(:slot, status: :running, execution_type: "cpu")
      Fabricate(:slot, status: :available, execution_type: "io")
    end

    it "sends for cpu execution type" do
      expect(slots_usage_percent_instance).to receive(:count).with(execution_type: "cpu", percent: 50.0)

      subject.perform
    end

    it "sends for io execution type" do
      expect(slots_usage_percent_instance).to receive(:count).with(execution_type: "io", percent: 0)

      subject.perform
    end
  end
end
