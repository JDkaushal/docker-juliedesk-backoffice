module DashboardDataGenerator

  def self.generate_data
    madagascar_start_of_day = DateTime.now.in_time_zone("Indian/Antananarivo").change({hour: 6}).utc
    madagascar_end_of_day = madagascar_start_of_day.clone + 1.day
    sent_messages_stat_data = self.generate_sent_messages_stat_data({
        start_date: madagascar_start_of_day.to_s,
        end_date: madagascar_end_of_day.to_s,
        precision: 30

                                                                    })

    inbox_count_data = self.generate_inbox_count_data
    operators_count_at_time_data = self.generate_operators_count_at_time_data

    REDIS_FOR_ACCOUNTS_CACHE.set("dashboard_data", {
        sent_messages_stat_data: sent_messages_stat_data,
        inbox_count_data: inbox_count_data,
        operators_count_at_time_data: operators_count_at_time_data,
        time: Time.now.to_s
    }.to_json)
  end

  def self.generate_sent_messages_stat_data params={}
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

    data
  end

  def self.generate_inbox_count_data
    # Get inbox messages_threads and associated accounts
    messages_threads = MessagesThread.where(in_inbox: true)
    accounts_cache = Account.accounts_cache(mode: "light")
    messages_threads.each{|mt| mt.account(accounts_cache: accounts_cache)}


    # Filter out messages_threads to process later on
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

    # Filter out sent_to_admin, not_associated and onyl_admin_can_process
    inbox_messages_threads = messages_threads.select{ |mt|
      !mt.sent_to_admin &&
          mt.account &&
          !mt.account.only_admin_can_process
    }

    # Filter in sent_to_admin, not_associated and onyl_admin_can_process
    admin_messages_threads = messages_threads.select{ |mt|
      mt.sent_to_admin ||
          !mt.account ||
          mt.account.only_admin_can_process
    }

    # Filter in prioritary messages_threads
    priority_messages_threads = messages_threads.select{ |mt|
      mt.account && mt.account.have_priority
    }

    # Get follow_up_messages_threads
    follow_up_messages_threads = messages_threads.select{|mt|
      "#{mt.subject}".downcase.include?("Récapitulatif hebdomadaire de la semaine du") || "#{mt.subject}".downcase.include?("weekly recap")
    } + MessagesThread.where(should_follow_up: true)

    # Filter in prioritary messages_threads among follow_up_messages_threads
    follow_up_messages_threads_priority = follow_up_messages_threads.select{|mt|
      mt.account && mt.account.have_priority
    }

    # Get productivity
    operator_action_groups_count = OperatorActionsGroup.where("finished_at > ? AND finished_at < ?", DateTime.now - 30.minutes, DateTime.now).where.not(label: OperatorActionsGroup::LABEL_ARCHIVE).count

    # Get operator presences
    operator_presences = OperatorPresence.where("date >= ? AND date < ?", DateTime.now - 30.minutes, DateTime.now).where(is_review: false).count

    # Compute delay
    messages = Message.where(from_me: true).where("received_at >= ? AND received_at <= ?", DateTime.now - 30.minutes, DateTime.now).where.not(request_at: nil)
    current_delay = ((ApplicationHelper.percentile(messages.map{|m| m.received_at - m.request_at}, 0.5) || 0) / 60.0).round(0)


    {
        count: inbox_messages_threads.length,
        admin_count: admin_messages_threads.length,
        global_productivity: operator_action_groups_count * 2,
        individual_productivity: operator_presences > 0 ? (operator_action_groups_count * 2.0 / operator_presences).round(1) : nil,
        current_delay: current_delay,
        priority_count: priority_messages_threads.length,
        follow_up_messages_threads_priority: follow_up_messages_threads_priority.length,
        follow_up_messages_threads_main: follow_up_messages_threads.length -  follow_up_messages_threads_priority.length,
    }
  end

  def self.generate_operators_count_at_time_data
    date = DateTime.now

    # Set to closest half-hour
    date = date.change(min: (date.min / 30) * 30)

    operator_presences = OperatorPresence.where(date: date, is_review: false).includes(:operator)

    connected_to_socket_user_emails = self.get_connected_to_socket_user_emails

    {
        operators_count: operator_presences.count,
        operators: operator_presences.map{|op|
          {
              name: op.operator.name,
              email: op.operator.email,
              privilege: op.operator.privilege,
              operator_of_the_month: op.operator.operator_of_the_month,
              present: connected_to_socket_user_emails.include?(op.operator.email),
              operator_id: op.operator_id
          }
        }
    }
  end

  def self.get_connected_to_socket_user_emails
    if ENV['PUSHER_APP_ID']
      Pusher.get("/channels/presence-global/users")[:users].map { |u| u['id'] }
    elsif ENV['RED_SOCK_URL']
      RedSock.get_channel_info("presence-global").map { |u| u['email'] }
    else
      []
    end
  end
end