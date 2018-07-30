require 'rails_helper'

RSpec.describe UpdateTaskStatusJob, type: :job do
  let(:node) { Node.create!(hostname: "local.test")}
  let(:slot) { Slot.create!(node: node) }
  let(:task_persist_logs) { false }
  let(:task) { Fabricate(:task, slot: slot, container_id: container_id, status: task_status, persist_logs: task_persist_logs) }
  let(:task_status) { "running" }
  let(:docker_connection) { double("Docker::Connection") }
  let(:container_id) { "11223344" }
  let(:container) { double("Docker::Container", info: container_info) }
  let(:container_status) { "exited" }
  let(:container_exit_code) { 0 }
  let(:container_error) { ""}
  let(:container_started_at) { "2018-04-23T10:12:37.4534537Z" }
  let(:container_finished_at) { "0001-01-01T00:00:00.0000000Z" }
  let(:container_info) do
    {
      "State" => {
        "Status" => container_status,
        "ExitCode" => container_exit_code,
        "Error" => container_error,
        "StartedAt" => container_started_at,
        "FinishedAt" => container_finished_at,
      }
    }
  end

  let(:perform) { subject.perform(task) }

  before do
    allow(Docker::Container).to receive(:get).with(container_id, {all: true}, docker_connection).and_return(container)
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
        expect{perform}.to change(task, :started_at).to(Time.parse(container_started_at))
      end

      it "sets task finish time" do
        expect{perform}.to change(task, :finished_at).to(Time.parse(container_finished_at))
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
        expect{perform}.to change(task, :started_at).to(Time.parse(container_started_at))
      end

      it "sets task finish time" do
        expect{perform}.to change(task, :finished_at).to(Time.parse(container_finished_at))
      end
    end

    context "and persist_logs flag is TRUE" do
      let(:logs) { "persist me" }
      let(:task_persist_logs) { true }

      before do
        allow(container).to receive(:streaming_logs).with(stdout: true, stderr: true).and_return(logs)
      end

      it "persist container logs to Task" do
        expect(task).to receive(:set_logs).with(logs)
        perform
      end
    end
  end

  context "when container stills running" do
    let(:container_status) { "running" }

    context "and task was running" do
      let(:task_status) { "running" }
      it "calls task running!" do
        expect(task).to receive(:running!)
        perform
      end
    end

    context "and task was not running" do
      let(:task_status) { "started" }

      it "updates task status" do
        expect{perform}.to change(task, :status).to("running")
      end
    end
  end
end
