# frozen_string_literal: true

require "rails_helper"

RSpec.describe Runners::Docker::FetchExecutionInfo, type: :service do
  let(:fetch_task_container_instance) { double(Runners::Docker::FetchTaskContainer) }
  let(:docker_container_instance) { double(::Docker::Container, info: info) }
  let(:info) do
    {
      "id" => "id",
      "State" => {
        "Status" => "Exited",
        "ExitCode" => 0,
        "StartedAt" => Time.current.to_s,
        "FinishedAt" => (Time.current + 1.minute).to_s,
        "Error" => "Error"
      }
    }
  end
  let(:task) { Fabricate(:task) }

  before do
    allow(Runners::ServicesFactory).to receive(:fabricate)
      .with(runner: :docker, service: :fetch_task_container)
      .and_return(fetch_task_container_instance)
    allow(fetch_task_container_instance).to receive(:perform)
      .with(task: task)
      .and_return(docker_container_instance)
  end

  subject { described_class.new.perform(task: task) }

  context "creates an execution info" do
    it "with id" do
      expect(subject.id).to eq(info["id"])
    end

    it "with status" do
      expect(subject.status).to eq(info["State"]["Status"])
    end

    it "with exit code" do
      expect(subject.exit_code).to eq(info["State"]["ExitCode"])
    end

    it "with started at" do
      expect(subject.started_at).to eq(info["State"]["StartedAt"])
    end

    it "with finished at" do
      expect(subject.finished_at).to eq(info["State"]["FinishedAt"])
    end

    it "with error" do
      expect(subject.error).to eq(info["State"]["Error"])
    end
  end
end
