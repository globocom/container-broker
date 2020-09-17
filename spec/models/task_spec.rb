# frozen_string_literal: true

require "rails_helper"

RSpec.describe Task, type: :model do
  let(:now) { Time.zone.now }
  let(:execution_type) { "test-type1" }
  let(:slot) { Fabricate(:slot) }
  subject { Fabricate(:task, execution_type: execution_type, slot: slot) }

  context "for new tasks" do
    it "saves creation date" do
      allow(Time.zone).to receive(:now).and_return(now)
      expect(subject.created_at).to eq(now)
    end

    it "starts with waiting status" do
      expect(described_class.new).to be_waiting
    end

    it "convert all tags values to string" do
      task = Fabricate(:task, tags: { api_id: 12_345 })
      task.reload

      expect(task.tags["api_id"]).to eq("12345")
    end

    it "calculates duration" do
      expect(subject.seconds_running).to be_nil
    end
  end

  context "with an invalid execution type" do
    let(:execution_type) { "invalid_type" }
    it "raises validation error" do
      expect { subject }.to raise_error(Mongoid::Errors::Validations)
    end
  end

  context "for started tasks" do
    subject do
      Fabricate(:task, started_at: "2018-01-25 15:32:10", finished_at: nil, status: "started")
    end

    before do
      allow(Time.zone).to receive(:now).and_return(Time.zone.parse("2018-01-25 15:33:00"))
    end

    it "calculates duration" do
      expect(subject.seconds_running).to eq(50)
    end
  end

  context "for completed tasks" do
    subject do
      Fabricate(:task, started_at: "2018-01-25 15:32:10", finished_at: "2018-01-25 15:32:32", status: "completed")
    end

    it "calculates duration" do
      expect(subject.seconds_running).to eq(22.seconds)
    end
  end

  context "for failing tasks" do
    context "with start and finish timestamps" do
      subject do
        Fabricate(:task, started_at: "2018-01-25 15:32:10", finished_at: "2018-01-25 15:32:32", status: "failed")
      end

      it "calculates duration" do
        expect(subject.seconds_running).to eq(22.seconds)
      end
    end

    context "without start and finish timestamps" do
      subject do
        Fabricate(:task, started_at: nil, finished_at: nil, status: "failed")
      end

      it "does not calculate duration" do
        expect(subject.seconds_running).to be_nil
      end
    end
  end

  context "for gettings logs" do
    context "and task has started" do
      let(:docker_fetch_logs_instance) { double(Runners::Docker::FetchLogs) }

      before do
        subject.started!

        allow(Runners::ServicesFactory).to receive(:fabricate)
          .with(runner: subject.slot.node.runner_provider, service: :fetch_logs)
          .and_return(docker_fetch_logs_instance)
      end

      it "fetches logs" do
        expect(docker_fetch_logs_instance).to receive(:perform).with(task: subject)

        subject.get_logs
      end
    end

    context "and task has not started" do
      before do
        subject.set_logs("test log")
      end

      it "fetches logs" do
        expect(subject.get_logs).to eq("test log")
      end
    end
  end

  context "generating runner id" do
    subject(:task) { Fabricate(:task, name: " Test - with Spaces, _ underlines and special chars. Very long name") }

    it "starts with an alphanumeric char" do
      expect(task.generate_runner_id).to start_with(/\w/)
    end

    it "ends with an alphanumeric char" do
      expect(task.generate_runner_id).to end_with(/\w/)
    end

    it "cannot include upper case letters" do
      expect(task.generate_runner_id).to_not match(/[A-Z]/)
    end

    it "cannot include spaces" do
      expect(task.generate_runner_id).to_not include(" ")
    end

    it "cannot include underline" do
      expect(task.generate_runner_id).to_not include("_")
    end

    it "need to be a DNS compatible name" do
      expect(task.generate_runner_id).to match(/[a-z0-9]([-a-z0-9]*[a-z0-9])?(\.[a-z0-9]([-a-z0-9]*[a-z0-9])?)*/)
    end

    it "limit length to MAX_NAME_SIZE" do
      expect(task.generate_runner_id).to have(Constants::Runner::MAX_NAME_SIZE).characters
    end
  end

  context "when status changes" do
    let(:observer_class) do
      Class.new(TaskObserver) do
        def status_change(old_value, new_value); end
      end
    end

    let(:observer) { observer_class.new(subject) }

    before do
      Task.add_observer(observer_class)

      allow(observer_class).to receive(:new).with(subject).and_return(observer)
    end

    after { Task.remove_observer(observer_class) }

    it "calls observers" do
      expect(observer).to receive(:status_change).with(subject.status, "completed")

      subject.completed!
    end
  end

  describe "validating storage mounts" do
    before do
      Fabricate(:node_kubernetes)
      Fabricate(:node_docker)
    end

    subject(:task) { Fabricate(:task, storage_mounts: storage_mounts) }

    context "when invalid" do
      let(:storage_mounts) do
        {
          "invalid" => "/tmp/invalid"
        }
      end

      it "raises an error" do
        expect { task }.to raise_error(Mongoid::Errors::Validations)
      end
    end

    context "when valid" do
      let(:storage_mounts) do
        {
          "temp" => "/tmp/invalid"
        }
      end

      it "does not raise an error" do
        expect { task }.to_not raise_error(Mongoid::Errors::Validations)
      end
    end
  end
end
