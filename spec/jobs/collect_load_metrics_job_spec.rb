# frozen_string_literal: true

require "rails_helper"

RSpec.describe CollectLoadMetricsJob, type: :job do
  let(:collect_load_metrics_instance) { instance_double(CollectLoadMetrics) }

  before do
    allow(CollectLoadMetrics).to receive(:new).and_return(collect_load_metrics_instance)
  end

  it "calls CollectLoadMetrics service" do
    expect(collect_load_metrics_instance).to receive(:perform)

    subject.perform
  end
end
