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

    render json: {
        status: "success",
        data: {
            count: inbox_messages_threads.length,
            admin_count: admin_messages_threads.length
        }
    }
  end

  def weekly_recap_data
    account_email = params[:email]
    unless account_email.present?
      render json: {
          status: "error",
          message: "missing required param email",
          data: {}
      }
      return
    end
    

    start_of_week = DateTime.now.beginning_of_week


    scheduled_mts = MessagesThread.were_statused_as({
                                        start_date: start_of_week,
                                        account_email: account_email,
                                        thread_status: MessageClassification::THREAD_STATUS_SCHEDULED
                                    }).
        includes(messages: {message_classifications: :julie_action}).
        select {|mt|
          status_before_this_week = mt.messages.map(&:message_classifications).flatten.select{|mc| mc.created_at < start_of_week}.sort_by(&:created_at).map(&:thread_status).last
          [MessageClassification::THREAD_STATUS_SCHEDULED].include?(mt.current_status) &&
              (status_before_this_week.nil? || status_before_this_week != mt.current_status)
        }

    scheduling_mts = MessagesThread.were_statused_as({
                                        start_date: DateTime.now - 1.month,
                                        account_email: account_email,
                                        thread_status: [MessageClassification::THREAD_STATUS_SCHEDULING_WAITING_FOR_CLIENT, MessageClassification::THREAD_STATUS_SCHEDULING_WAITING_FOR_CONTACT]
                                    }).
        includes(messages: {message_classifications: :julie_action}).
        select {|mt|
          status_before_this_week = mt.messages.map(&:message_classifications).flatten.select{|mc| mc.created_at < start_of_week}.sort_by(&:created_at).map(&:thread_status).last
          [MessageClassification::THREAD_STATUS_SCHEDULING_WAITING_FOR_CLIENT, MessageClassification::THREAD_STATUS_SCHEDULING_WAITING_FOR_CONTACT].include?(mt.current_status) &&
            (status_before_this_week.nil? || status_before_this_week != mt.current_status)
        }

    event_creation_mts = MessagesThread.were_statused_as({
                                        start_date: start_of_week,
                                        account_email: account_email,
                                        thread_status: MessageClassification::THREAD_STATUS_EVENTS_CREATION
                                    }).
        includes(messages: {message_classifications: :julie_action}).
        select {|mt|
          status_before_this_week = mt.messages.map(&:message_classifications).flatten.select{|mc| mc.created_at < start_of_week}.sort_by(&:created_at).map(&:thread_status).last
          [MessageClassification::THREAD_STATUS_EVENTS_CREATION].include?(mt.current_status) &&
            (status_before_this_week.nil? || status_before_this_week != mt.current_status)
        }

    aborted_mts = MessagesThread.were_statused_as({
                                        start_date: DateTime.now - 1.month,
                                        account_email: account_email,
                                        thread_status: [MessageClassification::THREAD_STATUS_SCHEDULING_ABORTED]
                                    }).
        includes(messages: {message_classifications: :julie_action}).
        select {|mt|
          status_before_this_week = mt.messages.map(&:message_classifications).flatten.select{|mc| mc.created_at < start_of_week}.sort_by(&:created_at).map(&:thread_status).last
          [MessageClassification::THREAD_STATUS_SCHEDULING_ABORTED].include?(mt.current_status) &&
            (status_before_this_week.nil? || status_before_this_week != mt.current_status)
        }

    events_creation_data = event_creation_mts.map{|mt|
          mt.messages.map(&:message_classifications).
          flatten.
          map(&:julie_action).
          select{|ja| ja.done && ja.action_nature == JulieAction::JD_ACTION_CREATE_EVENT}.
          map{|ja| JSON.parse(ja.events || "[]")}
    }.flatten

    render json: {
        status: "success",
        data: {
            results: scheduled_mts.map{|mt|
              {
                  status: "scheduled",
                  subject: mt.computed_data_light[:summary],
                  other: {
                      date: "20150101120000",
                      event: mt.event_data,
                      last_message_received_at: mt.messages.sort_by(&:received_at).last.try(:received_at)
                  }
              }
            } + events_creation_data.map{|event|
              {
                  status: "scheduled",
                  other: {
                      event: event
                  }
              }
            } + scheduling_mts.select{|mt| mt.current_status == MessageClassification::THREAD_STATUS_SCHEDULING_WAITING_FOR_CONTACT}.map{|mt|
              {
                  status: "scheduling",
                  subject: mt.computed_data_light[:summary],
                  other: {
                      waiting_for: "contact",
                      valid_suggestions_count: mt.computed_data_light[:date_times].select{|dt| DateTime.parse(dt['date']) > DateTime.now}.length,
                      suggestions_count: mt.computed_data_light[:date_times].length,
                      last_message_received_at: mt.messages.sort_by(&:received_at).last.try(:received_at)
                  }
              }
            } + scheduling_mts.select{|mt| mt.current_status == MessageClassification::THREAD_STATUS_SCHEDULING_WAITING_FOR_CLIENT}.map{|mt|
              {
                  status: "scheduling",
                  subject: mt.computed_data_light[:summary],
                  other: {
                      waiting_for: "client",
                      valid_suggestions_count: mt.computed_data_light[:date_times].select{|dt| DateTime.parse(dt['date']) > DateTime.now}.length,
                      suggestions_count: mt.computed_data_light[:date_times].length,
                      last_message_received_at: mt.messages.sort_by(&:received_at).last.try(:received_at)
                  }
              }
            } + aborted_mts.map{|mt|
              {
                  status: "aborted",
                  subject: mt.computed_data_light[:summary],
                  other: {
                  }
              }
            }
        }
    }
  end
end