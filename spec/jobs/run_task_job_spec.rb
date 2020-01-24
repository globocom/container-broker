# frozen_string_literal: true

require "rails_helper"

RSpec.describe RunTaskJob, type: :job do
  let(:node) { Fabricate(:node) }
  let(:task) { Fabricate(:task, status: "starting") }
  let(:slot) { Fabricate(:slot_attaching, node: node) }
  let(:create_task_service) { double }
  let(:runner_id) { SecureRandom.hex }

  def perform
    subject.perform(task: task, slot: slot)
  end

  before do
    allow(Runners::ServicesFactory).to receive(:fabricate)
      .with(runner: node.runner, service: :run_task)
      .and_return(create_task_service)

    allow(create_task_service).to receive(:perform)
      .with(task: task, slot: slot, runner_id: runner_id)
      .and_return(runner_id)

    allow(task).to receive(:generate_runner_id).and_return(runner_id)
  end

  context "when run task returns an error" do
    shared_examples "releases slot and task" do
      it "releases the slot" do
        perform
        expect(slot).to be_idle
      end

      it "marks task to retry" do
        perform
        expect(task).to be_retry
      end

      it "increments retry count" do
        expect { perform }.to change(task, :try_count).by(1)
      end

      it "sets error message in the task" do
        expect { perform }.to change(task, :error).to(error_message)
      end
    end

    context "and the error is related with the specific node" do
      let(:error_message) { "Error connecting to docker" }

      before do
        allow(create_task_service).to receive(:perform).and_raise(Node::NodeConnectionError, error_message)
      end

      it "marks node as unstable" do
        perform
        expect(node).to be_unstable
      end

      include_examples "releases slot and task"
    end

    context "and the error is related to the task" do
      let(:error_message) { "Invalid image name" }

      before do
        allow(create_task_service).to receive(:perform).and_raise(StandardError, error_message)
      end

      it "does not mark node as unstable" do
        perform
        expect(node).to be_available
      end

      include_examples "releases slot and task"
    end
  end

  context "when run task succeeds" do
    it "updates task runner_id" do
      expect { perform }.to change(task, :runner_id).to(runner_id)
    end

    it "updates task status" do
      expect { perform }.to change { task.reload.status }.to("started")
    end

    it "updates task started_at" do
      expect { perform }.to change(task, :started_at).to(a_kind_of(Date))
    end

    it "does not update task finished_at" do
      expect { perform }.to_not change(task, :finished_at)
    end

    it "updates task slot" do
      expect { perform }.to change(task, :slot).to(slot)
    end

    it "updates slot status to running" do
      expect { perform }.to change(slot, :status).to("running")
    end

    it "updates slot current task" do
      expect { perform }.to change(slot, :current_task).to(task)
    end

    it "updates slot runner_id" do
      expect { perform }.to change(slot, :runner_id).to(runner_id)
    end
  end
end
