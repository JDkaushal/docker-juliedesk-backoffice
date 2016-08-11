class ConscienceWorker

  @queue = :conscience
  def self.enqueue(id)
    Resque.enqueue(self, id)
  end

  def self.perform (id)
    Message.find id
    m.interprete
  end
end