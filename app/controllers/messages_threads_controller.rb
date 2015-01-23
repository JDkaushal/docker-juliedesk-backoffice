class MessagesThreadsController < ApplicationController

  def index
    Message.import_emails
  end

  def show
    @messages_thread = MessagesThread.find(params[:id])
  end


end
