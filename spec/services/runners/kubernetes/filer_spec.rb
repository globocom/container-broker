# frozen_string_literal: true

RSpec.describe Runners::Kubernetes::Filer do
  subject(:perform) { described_class.new.perform(task_storage_mounts: storage_mounts) }

  context "with valid storage mounts" do
    let(:storage_mounts) do
      {
        "shared_nfs" => "/mnt/nfs/task"
      }
    end

    it "binds task storage mount with settings storage mount" do
      expect(perform).to match(
        hash_including(internal: [{ mountPath: "/mnt/nfs/task", name: "shared_nfs" }])
      )
    end

    it "binds task storage mount with settings storage mount" do
      expect(perform).to match(
        hash_including(external: [{ nfs: { server: "nfs.test", path: "/mnt/nfs/node" }, name: "shared_nfs" }])
      )
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
