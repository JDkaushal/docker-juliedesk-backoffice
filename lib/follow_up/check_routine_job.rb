module FollowUp

  class CheckRoutineJob

    def perform
      now = Time.now

      # All messages threads having a follow_up_reminder_date set that has been passed are tagged as should_follow_up,
      # so that they will appear on the home page in the follow up inbox

      # We don't forget to reset the follow_up_reminder_date attribute to prevent further emails sent
      MessagesThread.where('follow_up_reminder_date IS NOT NULL AND follow_up_reminder_date <= ?', now).update_all(should_follow_up: true, follow_up_reminder_date: nil)
    end
  end
end