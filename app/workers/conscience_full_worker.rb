class ConscienceFullWorker

  @queue = :conscience
  def self.enqueue(id)
    Resque.enqueue(self, id)
  end

  def self.perform (id)
    Ai::EmailProcessing::Processor.new(id, nil).process
  end
end