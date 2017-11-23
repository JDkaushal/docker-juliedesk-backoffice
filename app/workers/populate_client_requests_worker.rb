class PopulateClientRequestsWorker

  @queue = :low_priority_queue
  def self.enqueue(id)
    Resque.enqueue(self, id)
  end

  def self.perform (id)
    mt = MessagesThread.find id
    ClientRequest.create_if_needed(mt)
  end
end