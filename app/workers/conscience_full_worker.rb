class ConscienceFullWorker

  # We are using QUEUE=* so our queues are processed in alphabetical_order
  # We add a trailing 'a' to this queue name so it will be processed before the 'conscience' one that takes long to run
  @queue = :a_conscience_full_ai
  def self.enqueue(id)
    Resque.enqueue(self, id)
  end

  def self.perform (id)
    # We introduce a sleep of 2 sec to mitigate the problems the AI encounter when the DB follower is too slow to replicate the master
    # This result in the AI producing and error because the requested data is not yet available
    sleep(2)
    # New Jul.IA
    m = Message.find(id)
    m.interprete
    AutoMessageClassification.build_from_conscience(m.id, { for_real: true })
    #Ai::EmailProcessing::Processor.new(id, nil).process
  end
end
