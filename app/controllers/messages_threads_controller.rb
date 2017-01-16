class MessagesThreadsController < ApplicationController

  include ProfilerHelper

  layout "dashboard", only: [:index, :index_for_ai]
  before_filter :only_admin, only: [:history]

  before_action :check_staging_mode

  def index
    @operator_greetings_stats = Operator.find(session[:operator_id]).compute_daily_stats
    render_messages_threads
  end

  # Display only thread handled by the ai (handled_by_ai set to true)
  def index_for_ai
    render_messages_threads_ai
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

  def set_to_be_merged
    @messages_thread = MessagesThread.find(params[:id])

    operator_id = if params[:to_merge]
                    session[:operator_id]
                  else
                    nil
                  end

    @messages_thread.update(to_be_merged: params[:to_merge], to_be_merged_operator_id: operator_id)

    redirect_to messages_threads_path
  end

  def index_with_import
    Message.import_emails
    render_messages_threads
  end

  def index_with_import_ai
    Message.import_emails
    render_messages_threads_ai
  end

  def history
    @messages_thread = MessagesThread.includes(messages: {message_classifications: :julie_action}, operator_actions_groups: {operator_actions: {}, operator: {}}, mt_operator_actions: {operator: {}}).find(params[:id])

    @messages_thread.account
  end

  def show
    @messages_thread = MessagesThread.includes(messages: {message_interpretations: {}, message_classifications: :julie_action}, operator_actions_groups: {operator_actions: {}, operator: {}}).find(params[:id])

    OperatorAction.create_and_verify({
                                         initiated_at: DateTime.now,
                                         target: @messages_thread,
                                         nature: OperatorAction::NATURE_OPEN,
                                         operator_id: session[:operator_id],
                                         messages_thread_id: @messages_thread.id
                                     })
    # TODO Find way to reduce this time (3secs to timeout)
    @messages_thread.re_import

    @messages_thread.account

    @accounts_cache_light = Account.accounts_cache(mode: "light")

    @julie_emails = JulieAlias.all.map(&:email).map(&:downcase)
    @client_emails = @accounts_cache_light.map{|k, account| [account['email']] + account['email_aliases']}.flatten

    # TODO Don't forget to check if "account_email" is usable in calendar_login when calling computed_data method in place of "client_email"
    @messages_thread.create_event_title_review_if_needed

    #JSON.parse(REDIS_FOR_ACCOUNTS_CACHE.get('gregoire.lopez@tactill.com') || "{}")

    render :show
    #render nothing: true
  end

  def archive

    messages_thread = MessagesThread.includes(messages: {message_classifications: :julie_action}).find(params[:id])
    messages = messages_thread.messages

    last_email_status = messages_thread.last_email_status({messages: messages})

    if last_email_status == "from_me"
      last_message_classification = messages_thread.last_message_classification
      last_message_classification.update_attribute :thread_status, params[:thread_status]
    elsif last_email_status == "from_me_free_reply"
      last_message_classification = messages_thread.last_message_classification
      last_message_classification.update_attribute :thread_status, params[:thread_status]
    else
      last_message = messages.sort_by(&:updated_at).last
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

    should_update_reminder_date = params[:follow_up_reminder_enabled].present?

    # Voir pertinence à ce moment, on le fait sur l'index déjà normalement

    refreshed_messages = messages_thread.server_thread(force_refresh: true)['messages']

    if params[:current_messages_ids].present?
      current_messages_ids = params[:current_messages_ids].split(',')
      refreshed_messages_ids = refreshed_messages.map{|m| m['id'].to_s}

      missing_messages_ids = refreshed_messages_ids - current_messages_ids
    end

    # Check if number of message has growth in the meantime (which would mean that we received a new message)
    if missing_messages_ids && missing_messages_ids.size > 0
      #if messages_thread.server_thread(force_refresh: true)['messages'].find{|m| m['read']}.present?
      #if messages_thread.server_thread(force_refresh: true)['messages'].map{|m| m['read']}.select{|read| !read}.length > 0
      # We should not have to do that now, because we only archive it when no unread messages are present
      # EmailServer.unarchive_thread(messages_thread_id: messages_thread.server_thread_id)

      if should_update_reminder_date
        messages_thread.update(follow_up_reminder_date: params[:follow_up_reminder_date])
      end
      # We redirect the operator to the current thread show action, so he can continue to work on the thread
      # And we scroll to the bottom of the page to show the new message to the operator
      redirect_to messages_thread_path(messages_thread, scroll_to_bottom: true, not_read_messages: missing_messages_ids)
    else

      EmailServer.archive_thread(messages_thread_id: messages_thread.server_thread_id)

      messages.update_all(archived: true)

      data = {
          should_follow_up: false,
          status: params[:thread_status],
          in_inbox: false
      }

      if should_update_reminder_date
        data.merge!(follow_up_reminder_date: params[:follow_up_reminder_date])
      end

      messages_thread.update(data)

      if ENV['PUSHER_APP_ID']
        Pusher.trigger('private-global-chat', 'archive', {
            :message => 'archive',
            :message_thread_id => messages_thread.id
        })
      elsif ENV['RED_SOCK_URL']
        RedSock.trigger "private-global-chat", 'archive', {
                                                 message: "archive",
                                                 :message_thread_id => messages_thread.id
                                             }
      end

      # When the thread is archived we can redirect the operator to the threads list
      redirect_to action: :index
    end
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
       account_name: account.usage_name,
       account_association_merging_possible: false
                                        })

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

    if ENV['PUSHER_APP_ID']
      Pusher.trigger('private-global-chat', 'locks-changed', {
          :message => 'locks_changed',
          :locks_statuses => MessagesThread.get_locks_statuses_hash
      })
    elsif ENV['RED_SOCK_URL']
      RedSock.trigger 'private-global-chat', 'locks-changed', {
                                               :message => 'locks_changed',
                                               :locks_statuses => MessagesThread.get_locks_statuses_hash
                                           }
    end

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

    @accounts_cache_light = Account.accounts_cache(mode: "light")
    @julie_emails = JulieAlias.all.map(&:email).map(&:downcase)
    @client_emails = @accounts_cache_light.map{|k, account| [account['email']] + account['email_aliases']}.flatten

    render action: :preview, layout: "review"
  end

  def remove_data
    messages_thread = MessagesThread.find params[:id]
    messages_thread.operator_actions_groups.destroy_all
    messages_thread.mt_operator_actions.destroy_all
    # We reset the eventual auto matic follow up date, so it doesn't trigger in the future
    # We also
    messages_thread.update_attributes(
        was_merged: true,
        follow_up_reminder_date: nil,
        in_inbox: false
    )

    if ENV['PUSHER_APP_ID']
      Pusher.trigger('private-global-chat', 'archive', {
                                              :message => 'archive',
                                              :message_thread_id => messages_thread.id
                                          })
    elsif ENV['RED_SOCK_URL']
      RedSock.trigger 'private-global-chat', 'archive', {
                                               :message => 'archive',
                                               :message_thread_id => messages_thread.id
                                           }
    end

    render json: {
               status: "success",
               data: {}
           }
  end

  private

  def render_messages_threads_ai
    respond_to do |format|
      format.html {
      }
      format.json {
        @messages_thread = MessagesThread.where("handled_by_ai = TRUE").includes(messages: {}, locked_by_operator: {}).sort_by{|mt|
          mt.messages.select{|m| !m.archived}.map{|m| m.received_at}.min ||
              mt.messages.map{|m| m.received_at}.max ||
              DateTime.parse("2500-01-01")
        }

        @messages_thread.reverse!

        accounts_cache = Account.accounts_cache(mode: "light")
        @messages_thread.each{|mt| mt.account(accounts_cache: accounts_cache, messages_threads_from_today: @messages_threads_from_today, skip_contacts_from_company: true)}

        data = @messages_thread.as_json(include: :messages, methods: [:received_at, :account, :locked_by_operator_name], only: [:id, :locked_by_operator_id, :should_follow_up, :subject, :snippet, :sent_to_admin, :delegated_to_support, :server_thread_id, :last_operator_id, :status, :event_booked_date, :account_email, :to_be_merged])

        render json: {
                   status: "success",
                   message: "",
                   data: data
               }
      }


    end
  end

  def render_messages_threads
    respond_to do |format|
      format.html {

      }
      format.json {
        now = Time.now

        @operators_on_planning = Operator.select('operators.id, operators.name, operators.color').joins(:operator_presences).where('operator_presences.date >= ? AND operator_presences.date <= ?', now.beginning_of_hour, now.end_of_hour)
        @messages_threads_from_today = MessagesThread.distinct.where('date(created_at) = ?', now.to_date).group('account_email').count

        @messages_thread = MessagesThread.where("(in_inbox = TRUE OR should_follow_up = TRUE) AND handled_by_ai = FALSE AND handled_by_automation = FALSE").includes(locked_by_operator: {}, messages: :message_classifications).sort_by{|mt|
          mt.find_or_compute_request_date
        }

        accounts_cache = Account.accounts_cache(mode: "light")
        users_access_lost_cache = Account.users_with_lost_access

        @messages_thread.each do |mt|
          mt.check_if_blocked(users_access_lost_cache)
          mt.account(accounts_cache: accounts_cache, users_access_lost_cache: users_access_lost_cache, messages_threads_from_today: @messages_threads_from_today, skip_contacts_from_company: true)
        end

        MessagesThread.filter_on_privileges(session[:privilege], @messages_thread)

        # if session[:privilege] == Operator::PRIVILEGE_OPERATOR
        #   @messages_thread.select!{ |mt|
        #     !mt.delegated_to_founders &&
        #         !mt.delegated_to_support &&
        #         mt.account &&
        #         !mt.account.only_admin_can_process &&
        #         !mt.account.only_support_can_process &&
        #         !mt.to_be_merged
        #   }
        # elsif session[:privilege] == Operator::PRIVILEGE_SUPER_OPERATOR_LEVEL_1 || session[:privilege] == Operator::PRIVILEGE_SUPER_OPERATOR_LEVEL_2
        #   @messages_thread.select!{ |mt|
        #     !mt.delegated_to_founders &&
        #         (!mt.account || !mt.account.only_admin_can_process)
        #   }
        # end
        data = @messages_thread.as_json(methods: [:account, :locked_by_operator_name, :thread_blocked], only: [:id, :request_date, :messages_count, :locked_by_operator_id, :in_inbox, :should_follow_up, :subject, :snippet, :sent_to_admin, :delegated_to_support, :server_thread_id, :last_operator_id, :status, :event_booked_date, :account_email, :to_be_merged, :is_multi_clients])
        operators_data = @operators_on_planning.as_json

        render json: {
            status: "success",
            message: "",
            data: data,
            operators_data: operators_data
        }
      }
    end
  end
end
