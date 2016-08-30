class RequestAtWorker

  @queue = :messages_threads
  def self.enqueue(id)
    Resque.enqueue(self, id)
  end

  def self.perform (id)
    mt = MessagesThread.find id
    mt.compute_messages_request_at
  end
end