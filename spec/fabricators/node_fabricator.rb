Fabricator(:node) do
  name "Node"
  hostname "worker.test"
  cores 8
  memory 32768
  status "available"
end
