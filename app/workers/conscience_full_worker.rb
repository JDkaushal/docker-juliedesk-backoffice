class ConscienceFullWorker

  # We are using QUEUE=* so our queues are processed in alphabetical_order
  # We add a trailing 'a' to this queue name so it will be processed before the 'conscience' one that takes long to run
  @queue = :a_conscience_full_ai
  def self.enqueue(message_id)
    Resque.enqueue(self, message_id)
  end

  def self.perform (message_id)
    AutomaticProcessing::AutomatedMessageClassification.process_message_id(message_id)
  end
end
