# frozen_string_literal: true

require "rails_helper"

RSpec.describe Runners::Kubernetes::FetchExecutionInfo, type: :service do
  let(:kubernetes_client_instance) { double(KubernetesClient) }
  let(:node) { Fabricate(:node_kubernetes) }
  let(:job_name) { "job-name" }
  let(:slot) { Fabricate(:slot_running, node: node) }
  let(:task) { Fabricate(:task, container_id: job_name, slot: slot) }
  let(:started_at) { Time.current.to_s }
  let(:finished_at) { (Time.current + 1.minute).to_s }

  before do
    allow(node).to receive(:kubernetes_client).and_return(kubernetes_client_instance)
    allow(kubernetes_client_instance).to receive(:fetch_pod)
      .with(job_name: job_name)
      .and_return(pod)
  end

  context "when job was not started" do
    let(:pod) do
      Kubeclient::Resource.new
    end

    context "fetches execution info" do
      subject(:execution_info) { described_class.new.perform(task: task) }

      it "with status" do
        expect(execution_info.status).to be_nil
      end

      it "with exit code" do
        expect(execution_info.exit_code).to be_nil
      end

      it "with started at" do
        expect(execution_info.started_at).to be_nil
      end

      it "with finished at" do
        expect(execution_info.finished_at).to be_nil
      end

      it "with error" do
        expect(execution_info.error).to be_nil
      end
    end
  end

  context "when job is running" do
    let(:pod) do
      Kubeclient::Resource.new(
        status: {
          containerStatuses: [
            {
              state: {
                running: {
                  startedAt: started_at
                }
              }
            }
          ]
        }
      )
    end

    context "fetches execution info" do
      subject(:execution_info) { described_class.new.perform(task: task) }

      it "with status" do
        expect(execution_info.status).to eq("started")
      end

      it "with exit code" do
        expect(execution_info.exit_code).to be_nil
      end

      it "with started at" do
        expect(execution_info.started_at).to eq(started_at)
      end

      it "with finished at" do
        expect(execution_info.finished_at).to be_nil
      end

      it "with error" do
        expect(execution_info.error).to be_nil
      end
    end
  end

  context "when job was completed" do
    context "and it's successfully" do
      let(:pod) do
        Kubeclient::Resource.new(
          status: {
            containerStatuses: [
              {
                state: {
                  terminated: {
                    exitCode: 0,
                    reason: "Completed",
                    startedAt: started_at,
                    finishedAt: finished_at
                  }
                }
              }
            ]
          }
        )
      end

      context "fetches execution info" do
        subject(:execution_info) { described_class.new.perform(task: task) }

        it "with status" do
          expect(execution_info.status).to eq("exited")
        end

        it "with exit code" do
          expect(execution_info.exit_code).to eq(0)
        end

        it "with started at" do
          expect(execution_info.started_at).to eq(started_at)
        end

        it "with finished at" do
          expect(execution_info.finished_at).to eq(finished_at)
        end

        it "with error" do
          expect(execution_info.error).to be_nil
        end
      end
    end

    context "and it's failed" do
      let(:pod) do
        Kubeclient::Resource.new(
          status: {
            containerStatuses: [
              {
                state: {
                  terminated: {
                    exitCode: 127,
                    reason: "Error",
                    startedAt: started_at,
                    finishedAt: finished_at
                  }
                }
              }
            ]
          }
        )
      end

      context "fetches execution info" do
        subject(:execution_info) { described_class.new.perform(task: task) }

        it "with status" do
          expect(execution_info.status).to eq("exited")
        end

        it "with exit code" do
          expect(execution_info.exit_code).to eq(127)
        end

        it "with started at" do
          expect(execution_info.started_at).to eq(started_at)
        end

        it "with finished at" do
          expect(execution_info.finished_at).to eq(finished_at)
        end

        it "with error" do
          expect(execution_info.error).to eq("Error")
        end
      end
    end
  end
end
