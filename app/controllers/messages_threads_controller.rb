class MessagesThreadsController < ApplicationController

  def index

    @messages_thread = MessagesThread.where(in_inbox: true).includes(messages: :message_classifications).sort_by{|mt| mt.messages.map{|m| m.received_at}.max}.reverse
  end

  def index_with_import
    Message.import_emails
    redirect_to action: :index
  end

  def show
    @messages_thread = MessagesThread.includes(messages: :message_classifications).find(params[:id])
    @messages_thread.re_import
  end

  def archive
    messages_thread = MessagesThread.find(params[:id])
    messages_thread.google_thread.mark_as_read
    messages_thread.google_thread.archive
    Message.where(messages_thread_id: messages_thread.id).update_all(archived: true)
    redirect_to action: :index
  end

  def split
    messages_thread = MessagesThread.find(params[:id])
    messages_thread.split(params[:message_ids].map(&:to_i))
    render json: {
        status: "success",
        message: "",
        data: {

        }
    }
  end

end
