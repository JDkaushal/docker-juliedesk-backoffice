mts = MessagesThread.where('created_at > ?', DateTime.now - 6.months)
mts.each_with_index do |mt, i|
  puts "#{i}/#{mts.count}"
  ClientRequest.create_if_needed(mt)
end