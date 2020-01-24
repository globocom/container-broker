# frozen_string_literal: true

require "rails_helper"

RSpec.describe UpdateTaskStatusJob, type: :job do
  let(:node) { Fabricate(:node) }
  let(:slot) { Fabricate(:slot_idle, node: node, execution_type: "test") }
  let(:task_persist_logs) { false }
  let(:task) { Fabricate(:task, slot: slot, runner_id: runner_id, status: task_status, persist_logs: task_persist_logs) }
  let(:task_status) { "running" }
  let(:docker_connection) { double("Docker::Connection") }
  let(:runner_id) { "11223344" }
  let(:container) { double("Docker::Container", id: runner_id, info: container_info) }
  let(:container_status) { "exited" }
  let(:container_exit_code) { 0 }
  let(:container_error) { "" }
  let(:container_started_at) { "2018-04-23T10:12:37.4534537Z" }
  let(:container_finished_at) { "2018-04-23T10:12:47.4534537Z" }
  let(:container_info) do
    {
      "State" => {
        "Status" => container_status,
        "ExitCode" => container_exit_code,
        "Error" => container_error,
        "StartedAt" => container_started_at,
        "FinishedAt" => container_finished_at
      }
    }
  end

  def perform
    subject.perform(task)
  end

  before do
    allow(Docker::Container).to receive(:get).with(runner_id, { all: true }, docker_connection).and_return(container)
    allow(node).to receive(:docker_connection).and_return(docker_connection)
  end

  context "when container exited" do
    let(:container_status) { "exited" }
    context "and exit code was zero" do
      let(:container_exit_code) { 0 }

      it "marks task as completed" do
        expect { perform }.to change(task, :status).to("completed")
      end

      it "clears task error" do
        perform
        expect(task.error).to be_blank
      end

      it "sets task exit code" do
        perform
        expect(task.exit_code).to be_zero
      end

      it "sets task start time" do
        expect { perform }.to change(task, :started_at).to(Time.parse(container_started_at))
      end

      it "sets task finish time" do
        expect { perform }.to change(task, :finished_at).to(Time.parse(container_finished_at))
      end

      context "generates metric" do
        before { allow(Settings.measures).to receive(:enabled).and_return(true) }

        let(:processing_time) { (container_finished_at.to_time - container_started_at.to_time).to_i }

        it "with processing_time" do
          expect_any_instance_of(Metrics).to receive(:count)
            .with(
              hash_including(processing_time: processing_time)
            )
          perform
        end
      end
    end

    context "and exit code WAS NOT zero" do
      let(:container_exit_code) { 52 }
      let(:container_error) { "Error running x" }
      it "sets task error" do
        perform
        expect(task.error).to eq("Error running x")
      end

      it "marks task to retry" do
        expect { perform }.to change(task, :status).to("retry")
      end

      it "sets task exit code" do
        perform
        expect(task.exit_code).to eq(52)
      end

      it "sets task start time" do
        expect { perform }.to change(task, :started_at).to(Time.parse(container_started_at))
      end

      it "sets task finish time" do
        expect { perform }.to change(task, :finished_at).to(Time.parse(container_finished_at))
      end
    end

    context "and persist_logs flag is TRUE" do
      let(:logs) { "persist me" }
      let(:task_persist_logs) { true }

      before do
        allow(container).to receive(:streaming_logs).with(stdout: true, stderr: true, tail: 1_000).and_return(logs)
      end

      it "persist container logs to Task" do
        expect(task).to receive(:set_logs).with(logs)
        perform
      end
    end
  end

  context "when container is running" do
    let(:container_status) { "running" }

    it "throws an exception" do
      expect { perform }.to raise_error(described_class::InvalidContainerStatusError)
    end
  end
end
