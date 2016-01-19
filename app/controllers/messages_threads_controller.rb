class MessagesThreadsController < ApplicationController

  layout "dashboard", only: [:index]
  before_filter :only_admin, only: [:history]

  before_action :check_staging_mode

  def index
    render_messages_threads
  end

  def search
    @messages_thread = MessagesThread.where(server_thread_id: params[:server_thread_ids]).includes(messages: {message_classifications: :julie_action}).sort_by{|mt|
      mt.messages.select{|m| !m.archived}.map{|m| m.received_at}.min ||
          mt.messages.map{|m| m.received_at}.max ||
          DateTime.parse("2500-01-01")
    }.reverse
    accounts_cache = Account.accounts_cache(mode: "light")
    @messages_thread.each{|mt| mt.account(accounts_cache: accounts_cache)}


    data = @messages_thread.as_json(include: [:messages], methods: [:received_at, :account, :computed_data, :event_data, :current_status])
    render json: {
        status: "success",
        message: "",
        data: data
    }
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
    @messages_thread = MessagesThread.includes(messages: {message_classifications: :julie_action}, operator_actions_groups: {operator_actions: {}, operator: {}}).find(params[:id])
    OperatorAction.create_and_verify({
                                         initiated_at: DateTime.now,
                                         target: @messages_thread,
                                         nature: OperatorAction::NATURE_OPEN,
                                         operator_id: session[:operator_id],
                                         messages_thread_id: @messages_thread.id
                                     })
    @messages_thread.re_import
    @messages_thread.account

    @accounts_cache_light = Account.accounts_cache(mode: "light")
    @julie_emails = JulieAlias.all.map(&:email).map(&:downcase)
    @client_emails = @accounts_cache_light.map{|k, account| [account['email']] + account['email_aliases']}.flatten


    @messages_thread.create_event_title_review_if_needed
  end

  def archive
    messages_thread = MessagesThread.includes(messages: {message_classifications: :julie_action}).find(params[:id])
    last_email_status = messages_thread.last_email_status
    if last_email_status == "from_me"
      last_message_classification = messages_thread.last_message_classification
      last_message_classification.update_attribute :thread_status, params[:thread_status]
    elsif last_email_status == "from_me_free_reply"
      last_message_classification = messages_thread.last_message_classification
      last_message_classification.update_attribute :thread_status, params[:thread_status]
    else
      last_message = messages_thread.messages.sort_by(&:updated_at).last
      message_classification = last_message.message_classifications.create_from_params classification: MessageClassification::NOTHING_TO_DO, operator: session[:user_username], thread_status: params[:thread_status]
      message_classification.julie_action.update_attribute :done, true
    end

    OperatorAction.create_and_verify({
                                         initiated_at: DateTime.now,
                                         target: messages_thread,
                                         nature: OperatorAction::NATURE_ARCHIVE,
                                         sub_nature: params[:thread_status],
                                         operator_id: session[:operator_id],
                                         messages_thread_id: messages_thread.id
                                     })

    EmailServer.archive_thread(messages_thread_id: messages_thread.server_thread_id)

    Message.where(messages_thread_id: messages_thread.id).update_all(archived: true)
    messages_thread.update_attribute :should_follow_up, false

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

  def preview
    @messages_thread = MessagesThread.includes(messages: {message_classifications: :julie_action}, operator_actions_groups: {operator_actions: {}, operator: {}}).find(params[:id])
    OperatorAction.create_and_verify({
                                         initiated_at: DateTime.now,
        target: @messages_thread,
        nature: OperatorAction::NATURE_OPEN,
        operator_id: session[:operator_id],
        messages_thread_id: @messages_thread.id
    })
    @messages_thread.re_import
    @messages_thread.account

    render action: :preview, layout: "review"
  end

  def remove_data
    messages_thread = MessagesThread.find params[:id]
    messages_thread.operator_actions_groups.destroy_all
    messages_thread.mt_operator_actions.destroy_all
    Pusher.trigger('private-global-chat', 'archive', {
                                            :message => 'archive',
                                            :message_thread_id => messages_thread.id
                                        })

    render json: {
               status: "success",
               data: {}
           }
  end

  private

  def render_messages_threads
    respond_to do |format|
      format.html {

      }
      format.json {
        @messages_thread = MessagesThread.where("in_inbox = TRUE OR should_follow_up = TRUE").includes(messages: {}, locked_by_operator: {}).sort_by{|mt|
          mt.messages.select{|m| !m.archived}.map{|m| m.received_at}.min ||
              mt.messages.map{|m| m.received_at}.max ||
              DateTime.parse("2500-01-01")
        }.reverse
        accounts_cache = Account.accounts_cache(mode: "light")
        @messages_thread.each{|mt| mt.account(accounts_cache: accounts_cache)}

        if session[:privilege] == Operator::PRIVILEGE_OPERATOR
          @messages_thread.select!{ |mt|
            !mt.delegated_to_founders &&
                !mt.delegated_to_support &&
                mt.account &&
                !mt.account.only_admin_can_process
          }
        elsif session[:privilege] == Operator::PRIVILEGE_SUPER_OPERATOR_LEVEL_1 || session[:privilege] == Operator::PRIVILEGE_SUPER_OPERATOR_LEVEL_2
          @messages_thread.select!{ |mt|
            !mt.delegated_to_founders &&
                (!mt.account || !mt.account.only_admin_can_process)
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
