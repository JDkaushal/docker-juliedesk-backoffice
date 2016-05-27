namespace :operator_stats do
  task :compute => :environment do |t|
    current_time = Time.now
    puts "Starting computing operator stats..."

    puts "Computing flagged messages_thread_ids..."
    flagged_server_messages_ids = []
    (0..3).each do |i|
      start_date = (DateTime.now - i.months).beginning_of_month
      end_date = (DateTime.now - i.months).end_of_month

      flagged_server_messages_ids += EmailServer.search_messages({
                                                                     after: start_date.to_s,
                                                                     before: end_date.to_s,
                                                                     labels: "flag",
                                                                     limit: 1000
                                                                 })['messages']['ids']
    end
    flagged_messages_thread_ids = Message.where(server_message_id: flagged_server_messages_ids).select(:messages_thread_id).distinct.map(&:messages_thread_id)
    puts "Processed in #{Time.now - current_time}."
    current_time = Time.now

    Operator.where(active: true).each_with_index do |operator, i|
      current_time = Time.now
      puts "Processing #{operator.name} stats (#{i + 1}/#{Operator.where(active: true).count})..."
      DATA_CACHE_REDIS["operator_stats-#{operator.id}"] = Operator.generate_stats_data([operator.id], flagged_messages_thread_ids).to_json
      puts "Processed in #{Time.now - current_time}."
      current_time = Time.now
    end

    puts "Processing team stats..."
    DATA_CACHE_REDIS["operator_stats_team"] = Operator.generate_stats_data(Operator.where(privilege: [Operator::PRIVILEGE_OPERATOR, Operator::PRIVILEGE_SUPER_OPERATOR_LEVEL_1, Operator::PRIVILEGE_SUPER_OPERATOR_LEVEL_2]).map(&:id), flagged_messages_thread_ids).to_json
    puts "Processed in #{Time.now - current_time}."
    current_time = Time.now

    puts "Processing level 1 stats..."
    DATA_CACHE_REDIS["operator_stats_level_1"] = Operator.generate_stats_data(Operator.where(privilege: [Operator::PRIVILEGE_OPERATOR]).map(&:id), flagged_messages_thread_ids).to_json
    puts "Processed in #{Time.now - current_time}."
  end
end