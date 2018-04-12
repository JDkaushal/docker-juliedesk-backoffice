class ConscienceWorker

  @queue = :conscience
  def self.enqueue(id)
    Resque.enqueue(self, id)
  end

  def self.perform (id)
    m = Message.find_by_id id
    m.interprete! unless m.nil?
  end
end