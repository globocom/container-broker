# frozen_string_literal: true

require "rails_helper"

RSpec.describe Runners::Docker::CreateExecutionInfo, type: :service do
  let(:started_at) { Time.current }
  let(:finished_at) { Time.current + 5.minutes }
  let(:container_name) { "container-name" }

  context "when container was created" do
    let(:container) do
      double(
        ::Docker::Container,
        info: {
          "id" => "id",
          "Names" => [container_name],
          "State" => {
            "Status" => "created"
          }
        }
      )
    end
    subject { described_class.new.perform(container: container) }

    context "creates pending execution info" do
      it "with id" do
        expect(subject.id).to eq(container_name)
      end

      it "with status" do
        expect(subject.status).to eq("pending")
      end

      it "with exit code" do
        expect(subject.exit_code).to be_nil
      end

      it "with started at" do
        expect(subject.started_at).to be_nil
      end

      it "with finished at" do
        expect(subject.finished_at).to be_nil
      end

      it "with error" do
        expect(subject.error).to be_nil
      end
    end
  end

  context "when container is running" do
    let(:container) do
      double(
        ::Docker::Container,
        info: {
          "id" => "id",
          "Names" => [container_name],
          "State" => {
            "Status" => "running",
            "StartedAt" => started_at
          }
        }
      )
    end
    subject { described_class.new.perform(container: container) }

    context "creates running execution info" do
      it "with id" do
        expect(subject.id).to eq(container_name)
      end

      it "with status" do
        expect(subject.status).to eq("running")
      end

      it "with exit code" do
        expect(subject.exit_code).to be_nil
      end

      it "with started at" do
        expect(subject.started_at).to eq(started_at)
      end

      it "with finished at" do
        expect(subject.finished_at).to be_nil
      end

      it "with error" do
        expect(subject.error).to be_nil
      end
    end
  end

  context "when container was exited" do
    context "and it's successfully" do
      let(:container) do
        double(
          ::Docker::Container,
          info: {
            "id" => "id",
            "Names" => [container_name],
            "State" => {
              "Status" => "exited",
              "StartedAt" => started_at,
              "FinishedAt" => finished_at,
              "ExitCode" => 0
            }
          }
        )
      end
      subject { described_class.new.perform(container: container) }

      context "creates success execution info" do
        it "with id" do
          expect(subject.id).to eq(container_name)
        end

        it "with status" do
          expect(subject.status).to eq("success")
        end

        it "with exit code" do
          expect(subject.exit_code).to eq(0)
        end

        it "with started at" do
          expect(subject.started_at).to eq(started_at)
        end

        it "with finished at" do
          expect(subject.finished_at).to eq(finished_at)
        end

        it "with error" do
          expect(subject.error).to be_nil
        end
      end
    end

    context "and it's failed" do
      let(:container) do
        double(
          ::Docker::Container,
          info: {
            "id" => "id",
            "Names" => [container_name],
            "State" => {
              "Status" => "exited",
              "StartedAt" => started_at,
              "FinishedAt" => finished_at,
              "ExitCode" => 127
            }
          }
        )
      end
      subject { described_class.new.perform(container: container) }

      context "creates error execution info" do
        it "with id" do
          expect(subject.id).to eq(container_name)
        end

        it "with status" do
          expect(subject.status).to eq("error")
        end

        it "with exit code" do
          expect(subject.exit_code).to eq(127)
        end

        it "with started at" do
          expect(subject.started_at).to eq(started_at)
        end

        it "with finished at" do
          expect(subject.finished_at).to eq(finished_at)
        end

        it "with error" do
          expect(subject.error).to be_nil
        end
      end
    end
  end

  context "when the state is just a status string" do
    let(:container) do
      double(
        ::Docker::Container,
        info: {
          "id" => "id",
          "Names" => [container_name],
          "State" => state
        }
      )
    end

    context "running" do
      let(:state) { "running" }

      it "considers the state as the status" do
        expect(described_class.new.perform(container: container)).to be_running
      end
    end

    context "exited" do
      let(:state) { "exited" }

      it "considers the state as the status" do
        expect(described_class.new.perform(container: container)).to be_terminated
      end

      it "returns the exited status" do
        expect(described_class.new.perform(container: container).status).to eq("exited")
      end
    end
  end
end
