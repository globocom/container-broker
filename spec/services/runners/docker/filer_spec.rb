# frozen_string_literal: true

RSpec.describe Runners::Docker::Filer do
  subject(:perform) { described_class.new.perform(task_storage_mounts: storage_mounts) }

  context "with valid storage mounts" do
    let(:storage_mounts) do
      {
        "shared_nfs" => "/mnt/nfs/task",
        "temp" => "/tmp/task"
      }
    end

    it "binds task storage mount with settings storage mount" do
      expect(perform).to contain_exactly("/mnt/nfs/node:/mnt/nfs/task", "/tmp/node:/tmp/task")
    end
  end

  context "with invalidvalid storage mounts" do
    let(:storage_mounts) do
      {
        "invalid_mount" => "/mnt/invalid_mount/task"
      }
    end

    it "binds task storage mount with settings storage mount" do
      expect { perform }.to raise_error(described_class::InvalidMountName)
    end
  end
end
