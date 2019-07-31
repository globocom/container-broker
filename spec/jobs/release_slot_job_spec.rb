require 'rails_helper'

RSpec.describe ReleaseSlotJob, type: :job do
  let(:node) { Node.create!(hostname: "local.test" ) }
  let(:slot) { Slot.create!(node: node, status: "releasing", current_task: task, container_id: container_id, execution_type: "test")}
  let(:task) { Fabricate(:task) }
  let(:container_id) { "11223344" }

  let(:perform) { subject.perform(slot: slot) }

  before do
    allow_any_instance_of(UpdateTaskStatusJob).to receive(:perform)
  end

  it "updates task status" do
    expect(UpdateTaskStatusJob).to receive(:perform_now).with(task)
    perform
  end

  it "schedules container removal from docker" do
    perform
    expect(RemoveContainerJob).to have_been_enqueued.with(node: slot.node, container_id: container_id)
  end

  it "releases the slot" do
    expect{perform}.to change(slot, :status).to("idle")
  end

  it "enqueues new tasks" do
    perform
    expect(RunTasksJob).to have_been_enqueued.at_least(1).times
  end
end
