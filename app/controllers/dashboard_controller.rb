class DashboardController < ApplicationController

  def dashboard
    Message.import_emails
    @messages_threads_count = MessagesThread.where(in_inbox: true).length
    @events_count = Event.where(classification: nil).count
  end
end
