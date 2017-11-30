require 'resque-timeout'

class ClientSuccessTrackingWithComputeWorker

  @queue = :client_success_tracking

  def self.enqueue(method_name, arg)
    Resque.enqueue(self, method_name, arg)
  end

  def self.perform (method_name, arg)
    begin
      ClientSuccessTrackingHelpers.send(method_name.to_sym, arg)
    rescue Exception => e
      print e.inspect
      print "TRACKING WORKER EXCEPTION\n"
      raise e
    end
  end
end