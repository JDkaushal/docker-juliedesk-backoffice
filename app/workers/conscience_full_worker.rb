class ConscienceFullWorker

  # We are using QUEUE=* so our queues are processed in alphabetical_order
  # We add a trailing 'a' to this queue name so it will be processed before the 'conscience' one that takes long to run
  @queue = :a_conscience_full_ai
  def self.enqueue(id)
    Resque.enqueue(self, id)
  end

  def self.perform (id)
    Ai::EmailProcessing::Processor.new(id, nil).process
  end
end