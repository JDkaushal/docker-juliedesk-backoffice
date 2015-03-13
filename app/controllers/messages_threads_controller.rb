class MessagesThreadsController < ApplicationController

  def index
    render_emails_threads
  end

  def index_with_import
    Message.import_emails
    render_emails_threads
  end

  def show
    @messages_thread = MessagesThread.includes(messages: {message_classifications: :julie_action}).find(params[:id])
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

  def associate_to_account
    messages_thread = MessagesThread.find(params[:id])
    account = Account.create_from_email(params[:account_email])
    if account
      messages_thread.update_attributes({
       account_email: account.email,
       account_name: account.usage_name})

      render json: {
          status: "success",
          data: {}
      }
    else
      render json: {
          status: "error",
          message: "No such account"
      }
    end
  end

  def remove_event_link
    messages_thread = MessagesThread.find(params[:id])
    message = messages_thread.messages.last
    mc = message.message_classifications.create_from_params classification: MessageClassification::ASK_CANCEL_APPOINTMENT, operator: session[:user_username], processed_in: 0
    mc.julie_action.update_attributes({
                                          done: true,
                                          deleted_event: true,
                                          processed_in: 0
                                      })

    redirect_to messages_thread
  end

  private

  def render_emails_threads
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
            data: @messages_thread.as_json(include: [:messages], methods: [:received_at, :account])
        }
      }
    end
  end

end
