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
      !mt.delegated_to_founders &&
          mt.account &&
          !mt.account.only_admin_can_process
    }

    admin_messages_threads = messages_threads.select{ |mt|
      mt.delegated_to_founders ||
          !mt.account ||
          mt.account.only_admin_can_process
    }


    processed_emails = Message.where(from_me: true).where("received_at >= ? AND received_at <= ?", DateTime.now - 30.minutes, DateTime.now).where.not(request_at: nil).count
    operator_presences = OperatorPresence.where("date >= ? AND date < ?", DateTime.now - 30.minutes, DateTime.now).where(is_review: false).count

    render json: {
        status: "success",
        data: {
            count: inbox_messages_threads.length,
            admin_count: admin_messages_threads.length,
            global_productivity: processed_emails * 2,
            individual_productivity: processed_emails * 2 / operator_presences
        }
    }
  end

  def sent_messages_stats
    start_date = (params[:start_date])? DateTime.parse(params[:start_date]) : (DateTime.now - 2.days)
    end_date = (params[:end_date])? DateTime.parse(params[:end_date]) : (DateTime.now)
    precision = (params[:precision].try(:to_i) || 30).minutes
    incoming_messages = Message.where(from_me: false).where("received_at >= ? AND received_at <= ?", start_date, end_date).select(:received_at)
    messages = Message.where(from_me: true).where("received_at >= ? AND received_at <= ?", start_date, end_date).where.not(request_at: nil)

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
      data[key] = {
          count: incoming_count,
          operators_count: current_operator_presences.length,
          median_delay: (ApplicationHelper.percentile(current_messages.map{|m| m.received_at - m.request_at}, 0.5) || 0) / 60.0,
          forecast_count: forecast_count
      }
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
end