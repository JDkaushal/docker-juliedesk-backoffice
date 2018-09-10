class RaiseWorker
  @queue = :archive

  def self.enqueue
    p "Enqueuing ..."
    Resque.enqueue(self)
  end

  def self.perform
    raise 'Error raised intentionaly'
  end
end
