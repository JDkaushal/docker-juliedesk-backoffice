mts = MessagesThread.where('created_at > ?', DateTime.now - 1.months).to_a

count = mts.count
i = 0
while mts.length > 0
  i += 1
  puts "#{i}/#{count}"
  mt = mts.pop
  ClientRequest.create_if_needed(mt)
end

MessagesThread.where('created_at > ?', DateTime.now - 6.months).select(:id).each do |mt|
  PopulateClientRequestsWorker.enqueue mt.id
end