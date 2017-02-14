class Api::V1::MessagesThreadsController < Api::ApiV1Controller

  def inbox_count
    messages_threads = MessagesThread.where(in_inbox: true)
    accounts_cache = Account.accounts_cache(mode: "light")
    messages_threads.each{|mt| mt.account(accounts_cache: accounts_cache)}


    messages_threads = messages_threads.select do |mt|
      if mt.account && mt.account.company_hash
        working_hours = mt.account.company_hash['working_hours']
        timezone = mt.account.company_hash['timezone']
        now = DateTime.now.in_time_zone(timezone)
        day = now.strftime("%a").downcase
        if working_hours[day]
          working_hours[day].select do |k, wh|
            hstart = wh[0].to_i
            hend = wh[1].to_i

            dstart = DateTime.now.in_time_zone(timezone).change({ hour: hstart/100, min: hstart%100, sec: 0 })
            dend = DateTime.now.in_time_zone(timezone).change({ hour: hend/100, min: hend%100, sec: 0 })
            now >= dstart && now <= dend
          end.length > 0
        else
          false
        end
      else
        true
      end
    end

    inbox_messages_threads = messages_threads.select{ |mt|
      !mt.sent_to_admin &&
          mt.account &&
          !mt.account.only_admin_can_process
    }

    admin_messages_threads = messages_threads.select{ |mt|
      mt.sent_to_admin ||
          !mt.account ||
          mt.account.only_admin_can_process
    }

    priority_messages_threads = messages_threads.select{ |mt|
      mt.account && mt.account.have_priority
    }

    follow_up_messages_threads = messages_threads.select{|mt|
      "#{mt.subject}".downcase.include?("Récapitulatif hebdomadaire de la semaine du") || "#{mt.subject}".downcase.include?("weekly recap")
    } + MessagesThread.where(should_follow_up: true)

    follow_up_messages_threads_priority = follow_up_messages_threads.select{|mt|
      mt.account && mt.account.have_priority
    }

    operator_action_groups_count = OperatorActionsGroup.where("finished_at > ? AND finished_at < ?", DateTime.now - 30.minutes, DateTime.now).where.not(label: OperatorActionsGroup::LABEL_ARCHIVE).count

    #processed_emails = Message.where(from_me: true).where("received_at >= ? AND received_at < ?", DateTime.now - 30.minutes, DateTime.now).count
    operator_presences = OperatorPresence.where("date >= ? AND date < ?", DateTime.now - 30.minutes, DateTime.now).where(is_review: false).count

    messages = Message.where(from_me: true).where("received_at >= ? AND received_at <= ?", DateTime.now - 30.minutes, DateTime.now).where.not(request_at: nil)
    current_delay = ((ApplicationHelper.percentile(messages.map{|m| m.received_at - m.request_at}, 0.5) || 0) / 60.0).round(0)

    render json: {
        status: "success",
        data: {
            count: inbox_messages_threads.length,
            admin_count: admin_messages_threads.length,
            global_productivity: operator_action_groups_count * 2,
            individual_productivity: (operator_action_groups_count * 2.0 / operator_presences).round(1),
            current_delay: current_delay,
            priority_count: priority_messages_threads.length,
            follow_up_messages_threads_priority: follow_up_messages_threads_priority.length,
            follow_up_messages_threads_main: follow_up_messages_threads.length -  follow_up_messages_threads_priority.length,
        }
    }
  end

  def sent_messages_stats
    start_date = (params[:start_date])? DateTime.parse(params[:start_date]) : (DateTime.now - 2.days)
    end_date = (params[:end_date])? DateTime.parse(params[:end_date]) : (DateTime.now)
    precision = (params[:precision].try(:to_i) || 30).minutes
    incoming_messages = Message.where(from_me: false).where("received_at >= ? AND received_at <= ?", start_date, end_date).select(:received_at)
    messages = Message.where(from_me: true).where("received_at >= ? AND received_at <= ?", start_date, end_date).where.not(request_at: nil)

    operator_action_groups = OperatorActionsGroup.where("finished_at >= ? AND finished_at <= ?", start_date, end_date).where.not(label: OperatorActionsGroup::LABEL_ARCHIVE)
    operator_presences = OperatorPresence.where(is_review: false).where("date >= ? AND date <= ?", start_date, end_date)
    current_start_date = start_date

    forecast = AiEmailFlowForecast.where('datetime >= ? AND datetime <= ?', start_date, end_date)

    data = {}
    while current_start_date < end_date

      forecast_count = (forecast.find{|f| f.datetime <= current_start_date + precision && f.datetime + 1.hour > current_start_date}.try(:count) || 0) / 2


      key = current_start_date.strftime("%Y%m%dT%H%M")
      current_messages = messages.select{|message| message.received_at >= current_start_date && message.received_at < current_start_date + precision}
      current_operator_presences = operator_presences.select{|operator_presence| operator_presence.date >= current_start_date && operator_presence.date < current_start_date + precision}
      incoming_count = incoming_messages.select{|message| message.received_at >= current_start_date && message.received_at < current_start_date + precision}.length

      operator_action_groups_count = operator_action_groups.select{|oag| oag.finished_at >= current_start_date && oag.finished_at < current_start_date + precision}.length
      if current_start_date + precision < DateTime.now
        data[key] = {
            count: incoming_count,
            operators_count: current_operator_presences.length,
            operator_action_groups_count: operator_action_groups_count,
            median_delay: (ApplicationHelper.percentile(current_messages.map{|m| m.received_at - m.request_at}, 0.5) || 0) / 60.0,
            forecast_count: forecast_count
        }
      else
        data[key] = {
            forecast_count: forecast_count
        }
      end
      current_start_date += precision
    end

    render json: {
               status: "success",
               data: data
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
    render json: AiProxy.new.build_request(:parse_sncf_ticket, { html_message: CGI.unescapeHTML(params[:html_message]) })
  end

  # Expect an array of server_message_ids and return the missing ones from the Backoffice DB
  # We cap at 10000 messages to prevent too big requests
  def check_missing_messages
    server_message_ids = params[:server_message_ids]
    render json: server_message_ids - Message.where(server_message_id: params[:server_message_ids]).first(10000).map(&:server_message_id)
  end
end