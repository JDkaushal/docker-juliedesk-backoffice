class Api::V1::MessagesThreadsController < Api::ApiV1Controller
  include Api::V1::Concerns::MessagesThreadsMethods

  def sent_messages_stats
    sent_messages_stats_data = DashboardDataGenerator.generate_sent_messages_stat_data({
                                                                                           start_date: params[:start_date],
                                                                                           end_date: params[:end_date],
                                                                                           precision: params[:precision]
                                                                                       })

    inbox_counts_data = JuliedeskTrackerInterface.new.build_request(:inbox_counts,
                                                                    {
                                                                        start_date: params[:start_date],
                                                                        end_date: params[:end_date]
                                                                    })['data']
    data = Hash[sent_messages_stats_data.map do |k, v|
        [k, v.merge({requests_count: inbox_counts_data[k].try(:[], 'count')})]
    end]

    render json: {
        status: "success",
        data: data
    }
  end

  def weekly_recap_data

    if params[:mode] == "activity_recap"
      [:email, :window_start_time, :window_end_time].each do |required_param|
        unless params[required_param].present?
          render json: {
              status: "error",
              message: "missing required param #{required_param}",
              data: {}
          }
          return
        end
      end

      window_start_time = DateTime.parse(params[:window_start_time])
      window_end_time = DateTime.parse(params[:window_end_time])

      render json: {
          status: "success",
          data: {
              results: WeeklyRecapHelper.get_activity_recap_data({
                                                                     account_email: params[:email],
                                                                     window_start_time: window_start_time,
                                                                     window_end_time: window_end_time
                                                                 })
          }
      }
    else
      [:email, :start_date].each do |required_param|
        unless params[required_param].present?
          render json: {
              status: "error",
              message: "missing required param #{required_param}",
              data: {}
          }
          return
        end
      end

      render json: {
          status: "success",
          data: {
              results: WeeklyRecapHelper.get_weekly_recap_data({
                                                                   account_email: params[:email],
                                                                   start_of_week: DateTime.parse(params[:start_date])
                                                               })
          }
      }
    end
  end

  def messages_thread_context
    @messages_thread = MessagesThread.includes(messages: {message_classifications: :julie_action}).find_by_server_thread_id(params[:id])

    render json: {
            thread: @messages_thread,
            messages: @messages_thread.messages,
            messages_classifications: @messages_thread.messages.map{ |m| {m.id => m.message_classifications} },
            julie_actions: @messages_thread.messages.map{|m| m.message_classifications.map{ |mc| {mc.id => mc.julie_action} }}.flatten,
            current_event: @messages_thread.event_data
           }

  end

  def parse_ticket
    render json: AI_PROXY_INTERFACE.build_request(:parse_sncf_ticket, { html_message: CGI.unescapeHTML(params[:html_message]) })
  end

  # Expect an array of server_message_ids and return the missing ones from the Backoffice DB
  # We cap at 10000 messages to prevent too big requests
  def check_missing_messages
    server_message_ids = params[:server_message_ids]
    render json: server_message_ids - Message.where(server_message_id: params[:server_message_ids]).first(10000).map(&:server_message_id)
  end

  def inbox_client_emails
    render json: { data: MessagesThread.client_emails_from_inbox }
  end

  def only_inbox_messages_server_ids
    render json: { data: MessagesThread.only_in_inbox_messages_server_ids }
  end

  def fetch_messages_threads
    render json: EmailServer.fetch_messages_thread(params)
  end

  def remove_syncing_tag
    data = valid_remove_syncing_tag_params(params)
    updated_threads = MessagesThread.remove_syncing_tag(data[:account_email])
    WebSockets::Manager.trigger_new_email([]) if updated_threads.size > 0
    render json: { nb_updated_threads: updated_threads.size }, status: :ok
  end

  def add_syncing_tag
    data = valid_add_syncing_tag_params(params)
    updated_threads = MessagesThread.add_syncing_tag(data[:account_email])
    WebSockets::Manager.trigger_new_email([]) if updated_threads.size > 0
    render json: { nb_updated_threads: updated_threads.size}, status: :ok
  end

  def compute_date_suggestions
    messages_thread = MessagesThread.includes(messages: { message_classifications: :julie_action }).find(params[:id])
    unless messages_thread.scheduling_status == MessagesThread::SCHEDULING_EVENT
      render json: { error_code: 'THREAD_NOT_SCHEDULING', message: '' }, status: :forbidden
      return
    end

    unless messages_thread.account && messages_thread.account.call_to_action_in_email_enabled
      render json: { error_code: 'FEATURE_NOT_ENABLED', message: '' }, status: :forbidden
      return
    end

    last_classification = messages_thread.last_message_classification_with_data
    julie_action = last_classification.julie_action

    json = AI_PROXY_INTERFACE.build_request(:fetch_dates_suggestions, {
        message_id: last_classification.message_id,
        julie_action_id: julie_action.try(:id),
        account_email: messages_thread.account_email,
        n_suggested_dates: 4,
        attendees: last_classification.get_present_attendees.map(&:to_h),
        thread_data: {
            appointment_nature: last_classification.appointment_nature,
            location: last_classification.location,
            duration: last_classification.duration,
            timezone: last_classification.timezone
        },
        raw_constraints_data: JSON.parse(last_classification.constraints_data || '[]')
    })

    suggested_dates = json['suggested_dates']
    if suggested_dates.present? && julie_action.present? && julie_action.action_nature == JulieAction::JD_ACTION_SUGGEST_DATES
      julie_action.date_times = suggested_dates.map { |date| { timezone: json['timezone'], date: date } }.to_json
      julie_action.save
    end

    render json: { suggested_dates: suggested_dates }, status: :ok

  rescue ActiveRecord::RecordNotFound
    render json: { error_code: 'THREAD_NOT_FOUND', message: "thread##{params[:id]} not found" }, status: :not_found
  end

  def validate_date_suggestion
    messages_thread = MessagesThread.includes(messages: { message_classifications: :julie_action}).find(params[:id])
    date_to_check  = DateTime.parse(params[:suggested_date])
    validated_by   = params[:validated_by]

    confirmed = MeetingService.new(messages_thread).confirm_suggested_date(date_to_check, validated_by)
    render json: { status: confirmed ? 'validated' : 'not_available' }, status: :ok

  rescue MeetingService::MeetingNotScheduling => e
    render json: { error_code: 'THREAD_NOT_SCHEDULING', message: e.message }, status: :forbidden
  rescue MeetingService::FeatureNotEnabled => e
    render json: { error_code: 'FEATURE_NOT_ENABLED', message: e.message }, status: :forbidden
  rescue MeetingService::NotAMeetingAttendee => e
    render json: { error_code: 'VALIDATOR_NOT_ATTENDEE', message: e.message }, status: :forbidden
  rescue MeetingService::SuggestedDateNotFound => e
    render json: { error_code: 'DATE_NOT_ALLOWED', message: e.message }, status: :forbidden
  rescue ActiveRecord::RecordNotFound
    render json: { error_code: 'THREAD_NOT_FOUND', message: "thread##{params[:id]} not found" }, status: :not_found
  end

end