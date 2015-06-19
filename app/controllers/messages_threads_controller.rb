class MessagesThreadsController < ApplicationController

  layout "dashboard", only: [:index]

  def index
    render_emails_threads
  end

  def index_with_import
    Message.import_emails
    render_emails_threads
  end

  def show
    @messages_thread = MessagesThread.includes(messages: {message_classifications: :julie_action}).find(params[:id])

    OperatorAction.create_and_verify({
                                         initiated_at: DateTime.now,
                                         target: @messages_thread,
                                         nature: OperatorAction::NATURE_OPEN,
                                         operator_id: session[:operator_id],
                                         messages_thread_id: @messages_thread.id
                                     })

    @messages_thread.re_import

    @messages_thread.account
  end

  def archive
    messages_thread = MessagesThread.find(params[:id])

    OperatorAction.create_and_verify({
                                         initiated_at: DateTime.now,
                                         target: messages_thread,
                                         nature: OperatorAction::NATURE_ARCHIVE,
                                         operator_id: session[:operator_id],
                                         messages_thread_id: messages_thread.id
                                     })

    messages_thread.google_thread.archive
    Message.where(messages_thread_id: messages_thread.id).update_all(archived: true)

    if messages_thread.google_thread(force_refresh: true).messages.map(&:unread?).select(&:present?).length > 0
      messages_thread.google_thread.unarchive
    else
      messages_thread.update_attribute(:in_inbox, false)

      Pusher.trigger('private-global-chat', 'archive', {
          :message => 'archive',
          :message_thread_id => messages_thread.id
      })
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

  def unlock
    messages_thread = MessagesThread.find(params[:id])
    messages_thread.update_attribute :locked_by_operator_id, nil

    Pusher.trigger('private-global-chat', 'locks-changed', {
        :message => 'locks_changed',
        :locks_statuses => MessagesThread.get_locks_statuses_hash
    })
    
    redirect_to messages_thread
  end

  private

  def render_emails_threads
    @messages_thread = MessagesThread.where(in_inbox: true).includes(messages: {message_classifications: {}}, locked_by_operator: {}).sort_by{|mt| mt.messages.map{|m| m.received_at}.max || DateTime.parse("2500-01-01")}.reverse

    accounts_cache = Account.accounts_cache
    @messages_thread.each{|mt| mt.account(accounts_cache: accounts_cache)}

    if session[:privilege] != "admin"
      @messages_thread.select!{ |mt|
        !mt.delegated_to_founders &&
            mt.account &&
            !mt.account.only_admin_can_process
      }
    end


    respond_to do |format|
      format.html {

      }
      format.json {
        render json: {
            status: "success",
            message: "",
            data: @messages_thread.as_json(include: [:messages], methods: [:received_at, :account, :locked_by_operator_name])
        }
      }
    end
  end

end
