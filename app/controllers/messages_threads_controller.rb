class MessagesThreadsController < ApplicationController

  def index

    allowed_accounts_for_operaror = "#{ENV['ALLOWED_ACCOUNTS_FOR_OPERATOR']}".split(",")
    @messages_thread = MessagesThread.where(in_inbox: true)
    if session[:user_username] == "operator@juliedesk.com"
      @messages_thread = @messages_thread.where(delegated_to_founders: false).where(account_email: allowed_accounts_for_operaror)
    end
    @messages_thread = @messages_thread.includes(messages: :message_classifications).sort_by{|mt| mt.messages.map{|m| m.received_at}.max}.reverse

    respond_to do |format|
      format.html {

      }
      format.json {
        render json: {
            status: "success",
            message: "",
            data: @messages_thread.as_json(include: [:messages], methods: [:received_at])
        }
      }
    end

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
    messages_thread.google_thread.archive
    Message.where(messages_thread_id: messages_thread.id).update_all(archived: true)

    if messages_thread.google_thread(force_refresh: true).messages.map(&:unread?).select(&:present?).length > 0
      messages_thread.google_thread.unarchive
    else
      messages_thread.update_attribute(:in_inbox, false)
    end

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
