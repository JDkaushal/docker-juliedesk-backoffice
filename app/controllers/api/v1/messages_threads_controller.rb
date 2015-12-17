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

    unless params[:start_date].present?
      render json: {
          status: "error",
          message: "missing required param email",
          data: {}
      }
      return
    end
    

    start_of_week = DateTime.parse(params[:start_date])


    scheduled_mts = MessagesThread.were_statused_as({
                                        start_date: start_of_week,
                                        account_email: account_email,
                                        thread_status: MessageClassification::THREAD_STATUS_SCHEDULED
                                    }).
        includes(messages: {message_classifications: :julie_action}).
        select {|mt|
          status_before_this_week = mt.messages.map(&:message_classifications).flatten.select{|mc| mc.created_at < start_of_week}.sort_by(&:created_at).map(&:thread_status).last
          [MessageClassification::THREAD_STATUS_SCHEDULED].include?(mt.current_status) &&
              (status_before_this_week.nil? || status_before_this_week != mt.current_status) &&
              mt.messages.select{|m| !m.from_me}.length > 0
        }

    scheduling_mts = MessagesThread.were_statused_as({
                                        start_date: start_of_week - 1.weeks,
                                        account_email: account_email,
                                        thread_status: [MessageClassification::THREAD_STATUS_SCHEDULING_WAITING_FOR_CLIENT, MessageClassification::THREAD_STATUS_SCHEDULING_WAITING_FOR_CONTACT]
                                    }).
        includes(messages: {message_classifications: :julie_action}).
        select {|mt|
          [MessageClassification::THREAD_STATUS_SCHEDULING_WAITING_FOR_CLIENT, MessageClassification::THREAD_STATUS_SCHEDULING_WAITING_FOR_CONTACT].include?(mt.current_status) &&
              mt.computed_data_light[:attendees].length > 0 &&
              mt.messages.select{|m| !m.from_me}.length > 0
        }

    scheduling_aborted_mts = MessagesThread.were_statused_as({
                                                         start_date: start_of_week - 2.weeks,
                                                         account_email: account_email,
                                                         thread_status: [MessageClassification::THREAD_STATUS_SCHEDULING_WAITING_FOR_CLIENT, MessageClassification::THREAD_STATUS_SCHEDULING_WAITING_FOR_CONTACT]
                                                     }).
        includes(messages: {message_classifications: :julie_action}).
        select {|mt|
      [MessageClassification::THREAD_STATUS_SCHEDULING_WAITING_FOR_CLIENT, MessageClassification::THREAD_STATUS_SCHEDULING_WAITING_FOR_CONTACT].include?(mt.current_status) &&
          mt.computed_data_light[:attendees].length > 0 &&
          mt.messages.select{|m| !m.from_me}.length > 0
    } - scheduling_mts

    event_creation_mts = MessagesThread.were_statused_as({
                                        start_date: start_of_week,
                                        account_email: account_email,
                                        thread_status: MessageClassification::THREAD_STATUS_EVENTS_CREATION
                                    }).
        includes(messages: {message_classifications: :julie_action}).
        select {|mt|
          status_before_this_week = mt.messages.map(&:message_classifications).flatten.select{|mc| mc.created_at < start_of_week}.sort_by(&:created_at).map(&:thread_status).last
          [MessageClassification::THREAD_STATUS_EVENTS_CREATION].include?(mt.current_status) &&
            (status_before_this_week.nil? || status_before_this_week != mt.current_status) &&
              mt.messages.select{|m| !m.from_me}.length > 0
        }

    aborted_mts = MessagesThread.were_statused_as({
                                        start_date: start_of_week,
                                        account_email: account_email,
                                        thread_status: [MessageClassification::THREAD_STATUS_SCHEDULING_ABORTED]
                                    }).
        includes(messages: {message_classifications: :julie_action}).
        select {|mt|
          status_before_this_week = mt.messages.map(&:message_classifications).flatten.select{|mc| mc.created_at < start_of_week}.sort_by(&:created_at).map(&:thread_status).last
          [MessageClassification::THREAD_STATUS_SCHEDULING_ABORTED].include?(mt.current_status) &&
            (status_before_this_week.nil? || status_before_this_week != mt.current_status) &&
              mt.computed_data_light[:attendees].length > 0 &&
              mt.messages.select{|m| !m.from_me}.length > 0
        }

    events_creation_data = event_creation_mts.map{|mt|
          julie_action = mt.messages.map(&:message_classifications).
            flatten.
            map(&:julie_action).
            select{|ja| ja.done && ja.action_nature == JulieAction::JD_ACTION_CREATE_EVENT}.
            sort_by(&:updated_at).
            last
          JSON.parse(julie_action.events || "[]").map{|ev| ev.merge({'messages_thread_id' => mt.id})}
    }.flatten

    all_message_thread_ids = MessagesThread.joins(:messages).
        where(messages_threads: {account_email: account_email}).
        where("messages.received_at > ?", DateTime.now - 2.weeks).distinct.map(&:id)

    all_message_thread_ids -= scheduled_mts.map(&:id)
    all_message_thread_ids -= scheduling_mts.map(&:id)
    all_message_thread_ids -= event_creation_mts.map(&:id)
    all_message_thread_ids -= aborted_mts.map(&:id)

    all_messages_threads = MessagesThread.where(id: all_message_thread_ids).includes(messages: :message_classifications).select{|mt|
      if mt.current_status == MessageClassification::THREAD_STATUS_SCHEDULED && mt.messages.map(&:received_at).max < start_of_week
        false
      elsif mt.current_status == MessageClassification::THREAD_STATUS_SCHEDULING_ABORTED && mt.messages.map(&:received_at).max < start_of_week
        false
      elsif mt.current_status == MessageClassification::THREAD_STATUS_EVENTS_CREATION && mt.messages.map(&:received_at).max < start_of_week
        false
      else
        true
      end
    }

    render json: {
        status: "success",
        data: {
            results: scheduled_mts.map{|mt|
              {
                  status: "scheduled",
                  subject: mt.computed_data_light[:summary],
                  other: {
                      id: mt.id,
                      date: "20150101120000",
                      event: mt.event_data,
                      last_message_received_at: mt.messages.select{|m| !m.from_me}.map(&:received_at).max
                  }
              }
            } + events_creation_data.map{|event|
              {
                  status: "scheduled",
                  other: {
                      id: event['messages_thread_id'],
                      event: event
                  }
              }
            } + scheduling_mts.select{|mt| mt.current_status == MessageClassification::THREAD_STATUS_SCHEDULING_WAITING_FOR_CONTACT}.map{|mt|
              {
                  status: "scheduling",
                  subject: mt.computed_data_light[:summary],
                  other: {
                      id: mt.id,
                      waiting_for: "contact",
                      valid_suggestions_count: mt.computed_data_light[:date_times].select{|dt| DateTime.parse(dt['date']) > DateTime.now}.length,
                      suggestions_count: mt.computed_data_light[:date_times].length,
                      appointment_nature: mt.computed_data_light[:appointment_nature],
                      attendees: mt.computed_data_light[:attendees].select{|att| att['isThreadOwner'] != "true" }.map { |att|
                        company = att['company']
                        if company == mt.computed_data_light[:attendees].select{|att| att['isThreadOwner'] == "true" }.first.try(:[], "company")
                          company = ""
                        end
                        {
                            name: [att['firstName'], att['lastName']].select(&:present?).join(" "),
                            company: company
                        }
                      },
                      last_message_received_at: mt.messages.select{|m| !m.from_me}.map(&:received_at).max
                  }
              }
            } + scheduling_mts.select{|mt| mt.current_status == MessageClassification::THREAD_STATUS_SCHEDULING_WAITING_FOR_CLIENT}.map{|mt|
              {
                  status: "scheduling",
                  subject: mt.computed_data_light[:summary],
                  other: {
                      id: mt.id,
                      waiting_for: "client",
                      valid_suggestions_count: mt.computed_data_light[:date_times].select{|dt| DateTime.parse(dt['date']) > DateTime.now}.length,
                      suggestions_count: mt.computed_data_light[:date_times].length,
                      appointment_nature: mt.computed_data_light[:appointment_nature],
                      attendees: mt.computed_data_light[:attendees].select{|att| att['isThreadOwner'] != "true" }.map { |att|
                        company = att['company']
                        if company == mt.computed_data_light[:attendees].select{|att| att['isThreadOwner'] == "true" }.first.try(:[], "company")
                          company = ""
                        end
                        {
                            name: [att['firstName'], att['lastName']].select(&:present?).join(" "),
                            company: company
                        }
                      },
                      last_message_received_at: mt.messages.select{|m| !m.from_me}.map(&:received_at).max
                  }
              }
            } + (aborted_mts + scheduling_aborted_mts).map{|mt|
              {
                  status: "aborted",
                  subject: mt.computed_data_light[:summary],
                  other: {
                      id: mt.id,
                      last_message_received_at: mt.messages.select{|m| !m.from_me}.map(&:received_at).max,
                      appointment_nature: mt.computed_data_light[:appointment_nature],
                      attendees: mt.computed_data_light[:attendees].select{|att| att['isThreadOwner'] != "true"}.map { |att|
                        company = att['company']
                        if company == mt.computed_data_light[:attendees].select{|att| att['isThreadOwner'] == "true" }.first.try(:[], "company")
                          company = ""
                        end
                        {
                            name: [att['firstName'], att['lastName']].select(&:present?).join(" "),
                            company: company
                        }
                      }
                  }
              }
            } + all_messages_threads.map{|mt|
              {
                  status: "all",
                  other: {
                      id: mt.id,
                      last_message_received_at: mt.messages.select{|m| !m.from_me}.map(&:received_at).max
                  }
              }
            }
        }
    }
  end
end