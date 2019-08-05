namespace :task do
  desc "Generate random tasks for testing"
  task :random_generate, %i[amount max_sleep] => [:environment] do |_task, args|
    amount = args.fetch(:amount, 500).to_i
    max_sleep = args.fetch(:max_sleep, 30).to_i

    execution_types = Slot
      .where(node_id: { '$in': Node.available.pluck(:id) })
      .pluck(:execution_type)
      .uniq

    raise "No slots available" if execution_types.empty?

    puts "Creating #{amount} tasks with max_sleep #{max_sleep}"
    amount.to_i.times do |index|
      print "."
      random_sleep = rand(max_sleep)
      execution_type = execution_types.sample
      Task.create!(
        name: "task-#{index}-sleep-#{random_sleep}-#{execution_type}",
        image: "busybox",
        cmd: "sleep #{random_sleep}",
        execution_type: execution_type,
        tags: {
          type: 'test'
        },
        persist_logs: true
      )
    end
    puts "\n Done!!"
  end
end
