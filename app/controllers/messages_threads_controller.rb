class MessagesThreadsController < ApplicationController

  layout "dashboard", only: [:index]
  before_filter :only_admin, only: [:history]

  def index
    render_messages_threads
  end

  def index_with_import
    Message.import_emails
    render_messages_threads
  end

  def history
    @messages_thread = MessagesThread.includes(messages: {message_classifications: :julie_action}, operator_actions_groups: {operator_actions: {}, operator: {}}, mt_operator_actions: {operator: {}}).find(params[:id])

    @messages_thread.account
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
                                         sub_nature: params[:sub_nature],
                                         operator_id: session[:operator_id],
                                         messages_thread_id: messages_thread.id
                                     })

    EmailServer.archive_thread(messages_thread_id: messages_thread.server_thread_id)

    Message.where(messages_thread_id: messages_thread.id).update_all(archived: true)

    if messages_thread.server_thread(force_refresh: true)['messages'].map{|m| m['read']}.select{|read| !read}.length > 0
      EmailServer.unarchive_thread(messages_thread_id: messages_thread.server_thread_id)
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

    last_message_classification = messages_thread.messages.map{|m|
      m.message_classifications
    }.flatten.sort_by(&:updated_at).select(&:has_data?).compact.last

    message_classification_params = {}
    if last_message_classification
      message_classification_params = last_message_classification.attributes.symbolize_keys.select{|k, v| [:appointment_nature, :summary, :duration, :location, :attendees, :notes, :constraints, :date_times, :locale, :timezone, :location_nature, :private, :other_notes, :constraints_data, :number_to_call].include? k}
    end

    mc = message.message_classifications.create message_classification_params.merge(classification: MessageClassification::ASK_CANCEL_APPOINTMENT, operator: session[:user_username], processed_in: 0)
    mc.append_julie_action
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

  def render_messages_threads
    respond_to do |format|
      format.html {

      }
      format.json {
        @messages_thread = MessagesThread.where(in_inbox: true).includes(messages: {}, locked_by_operator: {}).sort_by{|mt| mt.messages.map{|m| m.received_at}.max || DateTime.parse("2500-01-01")}.reverse
        accounts_cache = Account.accounts_cache(mode: "light")
        @messages_thread.each{|mt| mt.account(accounts_cache: accounts_cache)}
        if session[:privilege] != "admin"
          @messages_thread.select!{ |mt|
            !mt.delegated_to_founders &&
                mt.account &&
                !mt.account.only_admin_can_process
          }
        end

        data = @messages_thread.as_json(include: [:messages], methods: [:received_at, :account, :locked_by_operator_name])
        render json: {
            status: "success",
            message: "",
            data: data
        }
      }
    end
  end

  def print_time reference
    @i ||= 0
    @i+= 1
    p @i, Time.now - reference
  end


end
