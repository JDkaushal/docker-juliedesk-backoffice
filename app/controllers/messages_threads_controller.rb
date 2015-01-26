class MessagesThreadsController < ApplicationController

  def index
    Message.import_emails
    @messages_thread = MessagesThread.where(in_inbox: true).includes(messages: :message_classifications)
  end

  def show
    @messages_thread = MessagesThread.includes(messages: :message_classifications).find(params[:id])
  end

  def archive
    messages_thread = MessagesThread.find(params[:id])
    messages_thread.google_thread.archive
    redirect_to action: :index
  end

end
