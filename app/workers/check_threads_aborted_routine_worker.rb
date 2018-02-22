class CheckThreadsAbortedRoutineWorker

  @queue = :check_threads_aborted

  def self.enqueue
    Resque.enqueue(self)
  end

  def self.perform
    MessagesThreadFlows::CheckAbortionService.new.check
  end
end