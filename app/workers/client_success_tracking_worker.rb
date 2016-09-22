class ClientSuccessTrackingWorker

  @queue = :client_success_tracking

  def self.enqueue(event_name, user_id, properties)
    Resque.enqueue(self, event_name, user_id, properties)
  end

  def self.perform (event_name, user_id, properties)
    begin
      ClientSuccessTrackingHelpers.track(event_name, User.find(user_id), properties)
    rescue Exception => e
      print "TRACKING WORKER EXCEPTION\n"
      raise e
    end

  end
end