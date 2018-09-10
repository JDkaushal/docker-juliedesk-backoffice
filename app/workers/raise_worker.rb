require 'resque-retry'

class RaiseWorker
  extend Resque::Plugins::Retry
  @queue = :archive

  def self.enqueue
    p "Enqueuing ..."
    Resque.enqueue(self)
  end

  def self.perform
    raise 'Error raised intentionaly'
  end
end
