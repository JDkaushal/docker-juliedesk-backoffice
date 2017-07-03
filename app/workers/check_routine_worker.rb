class CheckRoutineWorker

  @queue = :follow_up

  def self.enqueue
    Resque.enqueue(self)
  end

  def self.perform
    now = Time.now

    # All messages threads having a follow_up_reminder_date set that has been passed are tagged as should_follow_up,
    # so that they will appear on the home page in the follow up inbox

    # We don't forget to reset the follow_up_reminder_date attribute to prevent further emails sent
    MessagesThread.where('follow_up_reminder_date IS NOT NULL AND follow_up_reminder_date <= ?', now).includes(messages: {message_classifications: :julie_action}).each do |mt|
      if mt.event_data[:event_id]
        mt.update(follow_up_reminder_date: nil)
      else
        mt.update(should_follow_up: true, follow_up_reminder_date: nil)
        mt.track_thread_in_inbox
      end
    end
  end
end