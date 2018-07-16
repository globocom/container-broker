Fabricator(:node) do
  name "Node"
  hostname "worker.test"
  cores 8
  memory 32768
  available true
  usage_percent 0
end
