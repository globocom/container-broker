# frozen_string_literal: true

require "rails_helper"

RSpec.describe Runners::Kubernetes::CreateExecutionInfo, type: :service do
  let(:started_at) { Time.current.to_s }
  let(:finished_at) { (Time.current + 1.minute).to_s }

  context "fetching id" do
    let(:pod) do
      Kubeclient::Resource.new(
        metadata: {
          labels: {
            "job-name": "id"
          }
        }
      )
    end
    subject { described_class.new.perform(pod: pod).id }

    it { is_expected.to eq("id") }
  end

  context "when job was not started" do
    let(:pod) do
      Kubeclient::Resource.new
    end

    context "fetches nil execution info" do
      subject { described_class.new.perform(pod: pod) }

      it "with status" do
        expect(subject.status).to be_nil
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

  context "when job is pending" do
    context "and has an error reason" do
      let(:pod) do
        Kubeclient::Resource.new(
          status: {
            containerStatuses: [
              {
                state: {
                  waiting: {
                    reason: "ImagePullBackOff",
                    message: "Back-off pulling image \"busyboxasdfadsfsd\""
                  }
                }
              }
            ]
          }
        )
      end

      context "fetches error execution info" do
        subject { described_class.new.perform(pod: pod) }

        it "with status" do
          expect(subject.status).to eq("error")
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
          expect(subject.error).to eq("ImagePullBackOff: Back-off pulling image \"busyboxasdfadsfsd\"")
        end
      end
    end

    context "and has not an error reason" do
      let(:pod) do
        Kubeclient::Resource.new(
          status: {
            containerStatuses: [
              {
                state: {
                  waiting: {
                    reason: "Unknown",
                    message: "unknown message"
                  }
                }
              }
            ]
          }
        )
      end

      context "fetches pending execution info" do
        subject { described_class.new.perform(pod: pod) }

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

    context "fetches running execution info" do
      subject { described_class.new.perform(pod: pod) }

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

      context "fetches success execution info" do
        subject { described_class.new.perform(pod: pod) }

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

      context "fetches error execution info" do
        subject { described_class.new.perform(pod: pod) }

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
          expect(subject.error).to eq("Error")
        end
      end
    end
  end
end
