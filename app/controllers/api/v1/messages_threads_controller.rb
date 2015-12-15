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

    # results = [
    #     {
    #         status: "scheduled",
    #         subject: "Call Alexandro Gonzales <> Julie Desk [Julien Hobeika]",
    #         other: {
    #             date: "20151118T130000"
    #         }
    #     },
    #     {
    #         status: "scheduled",
    #         subject: "Déjeuner Matthieu | L’Oréal | Julie Desk",
    #         other: {
    #             date: "20150412T123000"
    #         }
    #     },
    #     {
    #         status: "scheduling",
    #         subject: "Mtg avec Angel Kulk",
    #         other: {
    #             waiting_for: "contact",
    #             valid_suggestions_count: 4,
    #             suggestions_count: 4
    #         }
    #     },
    #     {
    #         status: "scheduling",
    #         subject: "Call avec Diego Delavega",
    #         other: {
    #             waiting_for: "client",
    #             valid_suggestions_count: 0,
    #             suggestions_count: 0
    #         }
    #     },
    #     {
    #         status: "scheduling",
    #         subject: "Déj avec Nicolas Berreau",
    #         other: {
    #             waiting_for: "contact",
    #             valid_suggestions_count: 0,
    #             suggestions_count: 4
    #         }
    #     },
    #     {
    #         status: "aborted",
    #         subject: "Mtg avec Minh Tralus"
    #     },
    #     {
    #         status: "aborted",
    #         subject: "Déj avec Jako Pastorius"
    #     }
    # ]

    start_of_week = DateTime.now.beginning_of_week
    end_of_week = DateTime.now.end_of_week

    messages_thread_ids = MessageClassification.where("message_classifications.created_at >= ? AND message_classifications.created_at <= ?", start_of_week, end_of_week).joins(message: :messages_thread).where(messages_threads: {account_email: account_email}).includes(message: :messages_thread).map{|mc| mc.message.messages_thread}.map(&:id)

    messages_threads = MessagesThread.where(id: messages_thread_ids).includes(messages: :message_classifications)

    messages_thread_statuses = messages_threads.map{|mt|
      statuses = mt.messages.map(&:message_classifications).flatten.map{|mc|
        {
            date: mc.created_at,
            thread_status: mc.thread_status
        }
      }.sort_by{|s| s[:date]}
      {
          id: mt.id,
          this_week_status: statuses.last.try(:[], :thread_status),
          before_this_week_status: statuses.select{|s| s[:date] < end_of_week}.last.try(:[], :thread_status)
      }
    }
    messages_thread_statuses.select{|mts|
      mts[:this_week_status] && (
        mts[:before_this_week_status].nil? ||
          mts[:before_this_week_status] != mts[:this_week_status]
      )
    }


    scheduled_this_week = MessagesThread.where(id: messages_thread_statuses.select{|mts| [MessageClassification::THREAD_STATUS_SCHEDULED].include? mts[:this_week_status]}.map{|mts| mts[:id]}).includes(messages: {message_classifications: :julie_action})
    scheduling_this_week_wf_contact = MessagesThread.where(id: messages_thread_statuses.select{|mts| [MessageClassification::THREAD_STATUS_SCHEDULING_WAITING_FOR_CONTACT].include? mts[:this_week_status]}.map{|mts| mts[:id]}).includes(messages: {message_classifications: :julie_action})
    scheduling_this_week_wf_client = MessagesThread.where(id: messages_thread_statuses.select{|mts| [MessageClassification::THREAD_STATUS_SCHEDULING_WAITING_FOR_CLIENT].include? mts[:this_week_status]}.map{|mts| mts[:id]}).includes(messages: {message_classifications: :julie_action})
    aborted_this_week = MessagesThread.where(id: messages_thread_statuses.select{|mts| [MessageClassification::THREAD_STATUS_SCHEDULING_ABORTED].include? mts[:this_week_status]}.map{|mts| mts[:id]}).includes(messages: {message_classifications: :julie_action})

    render json: {
        status: "success",
        data: {
            results: scheduled_this_week.map{|mt|
              {
                  status: "scheduled",
                  subject: mt.computed_data[:summary],
                  other: {
                      date: "20150101120000"
                  }
              }
            } + scheduling_this_week_wf_contact.map{|mt|
              {
                  status: "scheduling",
                  subject: mt.computed_data[:summary],
                  other: {
                      waiting_for: "contact",
                      valid_suggestions_count: mt.suggested_date_times.select{|dt| DateTime.parse(dt['date']) > DateTime.now}.length,
                      suggestions_count: mt.suggested_date_times.length
                  }
              }
            } + scheduling_this_week_wf_client.map{|mt|
              {
                  status: "scheduling",
                  subject: mt.computed_data[:summary],
                  other: {
                      waiting_for: "client",
                      valid_suggestions_count: mt.suggested_date_times.select{|dt| DateTime.parse(dt['date']) > DateTime.now}.length,
                      suggestions_count: mt.suggested_date_times
                  }
              }
            } + aborted_this_week.map{|mt|
              {
                  status: "aborted",
                  subject: mt.computed_data[:summary],
                  other: {
                  }
              }
            }
        }
    }
  end
end