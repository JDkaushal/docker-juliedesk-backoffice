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
                                                                        start_date: params[:start_date].to_s,
                                                                        end_date: params[:end_date].to_s
                                                                    })['data']
    data_from_analytics = Hash[inbox_counts_data.map do |k, v|
        [k, {requests_count: v['count']}]
    end]

    render json: {
        status: "success",
        data: sent_messages_stats_data.merge(data_from_analytics)
    }
  end

  def weekly_recap_data
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
    nb_updated_threads = MessagesThread.remove_syncing_tag(data[:account_email])
    WebSockets::Manager.trigger_new_email([]) if nb_updated_threads > 0
    render json: { nb_updated_threads: nb_updated_threads }, status: :ok
  end

  def add_syncing_tag
    data = valid_add_syncing_tag_params(params)
    nb_updated_threads = MessagesThread.add_syncing_tag(data[:account_email])
    WebSockets::Manager.trigger_new_email([]) if nb_updated_threads > 0
    render json: { nb_updated_threads: nb_updated_threads }, status: :ok
  end

end