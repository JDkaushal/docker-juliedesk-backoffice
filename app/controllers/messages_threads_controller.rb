class MessagesThreadsController < ApplicationController

  def index
    Message.import_emails
    @messages_thread = MessagesThread.where(in_inbox: true)
  end

  def show
    @messages_thread = MessagesThread.find(params[:id])
  end


end
