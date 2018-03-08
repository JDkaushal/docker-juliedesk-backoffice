
def reset_messages_threads
  MessagesThread.delete_all
  Message.delete_all
  MessageClassification.delete_all
  JulieAction.delete_all
end

def random_string length
  (0...length).map { ('a'..'z').to_a[rand(26)] }.join
end

def generate_messsages_thread
  mt = MessagesThread.create(
      in_inbox: true,
      account_email: "john.doe@#{random_string(8)}.com",
      subject: "#{random_string(10)} meeting",
      snippet: "Hello #{random_string(5)}, could you...",
      request_date: DateTime.now - (rand * 120).round.minutes
  )
  mt.messages << Message.new
end
reset_messages_threads
2.times {generate_messsages_thread}
