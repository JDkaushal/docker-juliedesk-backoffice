module WeeklyRecapHelper

  # Retrieve messages_threads
  # Parameters:
  #   start_of_week: Search after thi date
  #   account_email: only account email
  #   thread_statuses: only those thread statuses
  #   dont_check_status_has_changed_this_week: if true,...
  #   dont_check_attendees_present: if true,...
  def self.get_messages_threads params
    messages_threads = MessagesThread.
        joins(messages: :message_classifications).
        where("messages_threads.account_email = ? OR message_classifications.attendees LIKE ?", params[:account_email], "%#{params[:account_email]}%").
        where(messages_threads: {was_merged: false}).
        #where(messages_threads: {account_email: params[:account_email]}).
        where(message_classifications: {thread_status: params[:thread_statuses]}).
        where("message_classifications.created_at >= ?", params[:start_of_week]).
        select("DISTINCT ON (messages_threads.id) messages_threads.*").
        includes(messages: {message_classifications: :julie_action})

    messages_threads = messages_threads.select { |mt|
      mt.account_email == params[:account_email] ||
          mt.computed_data_only_attendees[:attendees].find{|att| att['account_email'] == params[:account_email] && att['isPresent'] == "true"}
    }

    messages_threads.select { |mt|
      mcs = mt.messages.map(&:message_classifications).flatten
      # When using an invitation_already_sent flow, the mt.computed_data_light[:attendees] is empty, as we do not fill the form up
      scheduled_from_invitation = mcs.map(&:classification).include?(MessageClassification::INVITATION_ALREADY_SENT)

      status_before_this_week = mcs.select { |mc| mc.created_at < params[:start_of_week] }.sort_by(&:created_at).map(&:thread_status).last
      params[:thread_statuses].include?(mt.current_status) &&
          (status_before_this_week.nil? || status_before_this_week != mt.current_status || params[:dont_check_status_has_changed_this_week]) &&
          (mt.computed_data_light[:attendees].length > 0 || scheduled_from_invitation || params[:dont_check_attendees_present]) &&
          mt.messages.select { |m| !m.from_me }.length > 0
    }
  end

  def self.get_currently_scheduling_threads(window_start_time, window_end_time, params)
    # Get the message classif on the specified window
    # Order them by date DESC LIMIT 1
    # Check if thread_status is one of the scheduling one

    scheduling_classifs = MessageClassification::SCHEDULING_CLASSIFICATIONS

    sql = <<-SQL.strip_heredoc
      SELECT DISTINCT ON(thread_id) thread_id AS id, last_status, not_from_me_mess_count
      FROM (
        SELECT
          mt1.id AS thread_id, 
          mc1.created_at,
          mc1.thread_status,
          FIRST_VALUE(mc1.thread_status) OVER (PARTITION BY mt1.id ORDER BY mc1.created_at DESC) as last_status,
          COUNT(m1.id) FILTER(WHERE m1.from_me = false) OVER (PARTITION BY m1.id) as not_from_me_mess_count
        FROM messages_threads mt1
        INNER JOIN messages m1 ON m1.messages_thread_id = mt1.id
        INNER JOIN message_classifications mc1 ON mc1.message_id = m1.id
        WHERE (mt1.account_email = '#{params[:account_email]}' OR mc1.attendees LIKE '%#{params[:account_email]}%') AND mc1.created_at <= '#{window_end_time}'
        AND ( ( mt1.aborted_at >= '#{window_start_time}' AND mt1.status <> '#{MessageClassification::THREAD_STATUS_SCHEDULING_ABORTED}' ) OR mt1.aborted_at <= '#{window_start_time}' OR mt1.aborted_at IS NULL )
        AND mt1.was_merged = false
        AND ( mc1.attendees <> '[]' OR mc1.thread_status = 'invitation_already_sent' )
      ) e1
      WHERE last_status IN (VALUES#{scheduling_classifs.map{|c| "('#{c}')"}.join(',')})
      AND not_from_me_mess_count > 0;
    SQL

    mts_ids = MessagesThread.find_by_sql(sql)
    mts = MessagesThread.includes(messages: {message_classifications: :julie_action}).find(mts_ids)

    mts.select { |mt|
      mt.account_email == params[:account_email] ||
          mt.computed_data_only_attendees[:attendees].find{|att| att['account_email'] == params[:account_email] && att['isPresent'] == "true"}
    }
  end

  def self.get_threads_coming_from_scheduling(window_start_time, window_end_time, params)

    classifs = params[:message_classif_thread_status_to_seek].present? ? params[:message_classif_thread_status_to_seek] : MessageClassification::CLASSIFICATIONS_WITH_DATA
    attendees_condition = params[:dont_check_attendees_present] ? "" : "AND ( mc1.attendees <> '[]' OR mc1.thread_status = 'invitation_already_sent' )"

    if params[:sought_status] == MessageClassification::THREAD_STATUS_SCHEDULING_ABORTED
      status_condition = "WHERE mt1.status = '#{params[:sought_status]}' AND mt1.aborted_at >= '#{window_start_time}'"
    else
      status_condition = "WHERE mt1.status = '#{params[:sought_status]}'"
    end

    sql = <<-SQL.strip_heredoc
      SELECT DISTINCT ON(thread_id) thread_id AS id, current_thread_status, previous_thread_status, not_from_me_mess_count
      FROM (
      SELECT mt1.id AS thread_id, mt1.status AS current_thread_status, COUNT(m1.id) FILTER(WHERE m1.from_me = false) OVER (PARTITION BY m1.id) as not_from_me_mess_count
      FROM messages_threads mt1
      INNER JOIN messages m1 ON m1.messages_thread_id = mt1.id
      INNER JOIN message_classifications mc1 ON mc1.message_id = m1.id
      #{status_condition}
      AND (mt1.account_email = '#{params[:account_email]}' OR mc1.attendees LIKE '%#{params[:account_email]}%')
      AND mt1.was_merged = false
      AND mc1.classification IN (VALUES#{classifs.map{|c| "('#{c}')"}.join(',')})
      #{attendees_condition}
      ) e1 LEFT JOIN LATERAL (
        SELECT mc2.thread_status AS previous_thread_status
        FROM message_classifications mc2
        INNER JOIN messages m3 ON m3.id = mc2.message_id
        WHERE m3.messages_thread_id = thread_id
        AND mc2.created_at < '#{window_start_time}'
        ORDER BY mc2.created_at DESC
        LIMIT 1
      ) e2 ON true
      WHERE (current_thread_status <> previous_thread_status OR previous_thread_status IS NULL)
      AND not_from_me_mess_count > 0;
    SQL

    # Retrieve the thread ids then query the database to get all the necessary informations
    # Did not found an easy way to get all the thread attriutes in the ROOT select of the query (would need to specify all the attributes by hand)
    mts_ids = MessagesThread.find_by_sql(sql)
    mts = MessagesThread.includes(messages: {message_classifications: :julie_action}).find(mts_ids)

    mts.select { |mt|
      mt.account_email == params[:account_email] ||
          mt.computed_data_only_attendees[:attendees].find{|att| att['account_email'] == params[:account_email] && att['isPresent'] == "true"}
    }
  end

  # Returns the date of the last message received as string
  def self.build_last_message_received_at mt
    mt.messages.select { |m| !m.from_me }.map(&:received_at).max
  end

  # Returns the attendees in format {name: STRING, company: STRING}
  # Ignores the attendee which is account_email, set company to empty string if in the same company as account_email one's.
  def self.build_attendees_array mt, account_email
    mt.computed_data_light[:attendees].select { |att| att['account_email'] != account_email && att['isPresent'] == "true" }.map { |att|
      company = att['company']
      if company == mt.computed_data_light[:attendees].select { |att| att['account_email'] == account_email }.first.try(:[], "company")
        company = ""
      end
      {
          email: att['email'],
          name: [att['firstName'], att['lastName']].select(&:present?).join(" "),
          company: company
      }
    }
  end


  # Get weekly recap data
  #
  # FORMAT IS AN ARRAY OF:
  # {
  #   status: "scheduled" | "scheduling" | "aborted",
  #   subject: <EVENT SUBJECT> | nil (nil for events creation)
  #   other: {
  #     id: <BACKOFFICE_MESSAGES_THREAD_ID>,
  #     event: {
  #       event_id: ,
  #       event_url: ,
  #       calendar_id: ,
  #       appointment_nature: ,
  #       calendar_login_username: ,
  #       event_from_invitation: ,
  #       event_from_invitation_organizer:
  #     },
  #     last_message_received_at: STRING,
  #     appointment_nature: STRING,
  #     attendees: [
  #       {
  #         name: STRING,
  #         company: STRING
  #       },
  #       ...
  #     ],
  #     waiting_for: "client" | "contact" | nil, (Only for scheduling)
  #     valid_suggestions_count: INTEGER, (Only for scheduling)
  #     suggestions_count: INTEGER, (Only for scheduling)
  #   }
  # }

  def self.get_weekly_recap_data params
    scheduled_mts = self.get_messages_threads({
                                                  start_of_week: params[:start_of_week],
                                                  account_email: params[:account_email],
                                                  thread_statuses: [MessageClassification::THREAD_STATUS_SCHEDULED]
                                              })

    event_creation_mts = self.get_messages_threads({
                                                       account_email: params[:account_email],
                                                       start_of_week: params[:start_of_week],
                                                       thread_statuses: [MessageClassification::THREAD_STATUS_EVENTS_CREATION],
                                                       dont_check_attendees_present: true

                                                   })
    events_creation_data = event_creation_mts.map {|mt|
      julie_action = mt.messages.map(&:message_classifications).
          flatten.
          map(&:julie_action).
          select{|ja| ja.done && ja.action_nature == JulieAction::JD_ACTION_CREATE_EVENT}.
          sort_by(&:updated_at).
          last
      JSON.parse(julie_action.try(:events) || "[]").map { |ev| ev.symbolize_keys.merge({
                                                                                           messages_thread_id: mt.id,
                                                                                           messages_thread_subject: mt.subject,
                                                                                           server_thread_id: mt.server_thread_id,
                                                                                       }) }
    }.flatten

    still_scheduling = []
    aborted_scheduling = []

    scheduling_mts = self.get_messages_threads({
                                                   account_email: params[:account_email],
                                                   start_of_week: params[:start_of_week] - 3.weeks,
                                                   thread_statuses: [MessageClassification::THREAD_STATUS_SCHEDULING_WAITING_FOR_CLIENT, MessageClassification::THREAD_STATUS_SCHEDULING_WAITING_FOR_CONTACT],
                                                   dont_check_status_has_changed_this_week: true
                                               })


    scheduling_mts.each do |mt|
      last_message_received_at = self.build_last_message_received_at(mt)
      computed_data_light = mt.computed_data_light
      attendees = self.build_attendees_array(mt, params[:account_email])

      # If the thread last message is less than 14 days olds we considere it is still scheduling
      # If not we consider it has been aborted


      if (params[:start_of_week] - last_message_received_at.to_datetime).to_i <= 14
        still_scheduling <<
            {
                account_email: params[:account_email],
                status: "scheduling",
                subject: computed_data_light[:summary],
                thread_subject: mt.subject,
                other: {
                    id: mt.id,
                    server_thread_id: mt.server_thread_id,
                    waiting_for: mt.current_status == MessageClassification::THREAD_STATUS_SCHEDULING_WAITING_FOR_CLIENT ? "client" : "contact",
                    valid_suggestions_count: computed_data_light[:date_times].select { |dt|
                      begin
                        DateTime.parse(dt['date']) > DateTime.now
                      rescue
                        false
                      end
                    }.length,
                    suggestions_count: computed_data_light[:date_times].length,
                    appointment_nature: computed_data_light[:appointment_nature],
                    attendees: attendees,
                    last_message_received_at: last_message_received_at.to_s,
                    follow_up_reminder_date: mt.follow_up_reminder_date ? mt.follow_up_reminder_date.to_s : nil
                }
            }
      else
        aborted_scheduling <<
            {
                account_email: params[:account_email],
                status: "aborted",
                subject: computed_data_light[:summary],
                thread_subject: mt.subject,
                other: {
                    id: mt.id,
                    server_thread_id: mt.server_thread_id,
                    last_message_received_at: last_message_received_at.to_s,
                    appointment_nature: computed_data_light[:appointment_nature],
                    attendees: attendees
                }
            }
      end
    end

    aborted_mts = self.get_messages_threads({
                                                account_email: params[:account_email],
                                                start_of_week: params[:start_of_week],
                                                thread_statuses: [MessageClassification::THREAD_STATUS_SCHEDULING_ABORTED]
                                            })



    aborted_scheduling += aborted_mts.map{ |mt|
      {
          account_email: params[:account_email],
          status: "aborted",
          subject: mt.computed_data_light[:summary],
          thread_subject: mt.subject,
          other: {
              id: mt.id,
              server_thread_id: mt.server_thread_id,
              last_message_received_at: self.build_last_message_received_at(mt).to_s,
              appointment_nature: mt.computed_data_light[:appointment_nature],
              attendees: self.build_attendees_array(mt, params[:account_email])
          }
      }
    }

    scheduled_mts.map { |mt|
      {
          account_email: params[:account_email],
          status: "scheduled",
          subject: mt.computed_data_light[:summary],
          thread_subject: mt.subject,
          other: {
              id: mt.id,
              server_thread_id: mt.server_thread_id,
              event: mt.event_data,
              attendees: self.build_attendees_array(mt, params[:account_email]),
              last_message_received_at: self.build_last_message_received_at(mt).to_s,
          }
      }
    } + events_creation_data.map { |event|
      {
          account_email: params[:account_email],
          status: "scheduled",
          thread_subject: event[:messages_thread_subject],
          other: {
              id: event[:messages_thread_id],
              server_thread_id: event[:server_thread_id],
              event: event,
              attendees: []
          }
      }
    } + still_scheduling + aborted_scheduling
  end
  
  def self.get_activity_recap_data params

    scheduled_mts = self.get_threads_coming_from_scheduling(params[:window_start_time], params[:window_end_time], {
                                                  account_email: params[:account_email],
                                                  sought_status: MessageClassification::THREAD_STATUS_SCHEDULED
                                              }).map do |mt|
      {
          account_email: params[:account_email],
          status: "scheduled",
          subject: mt.computed_data_light[:summary],
          thread_subject: mt.subject,
          other: {
              id: mt.id,
              server_thread_id: mt.server_thread_id,
              event: mt.event_data,
              attendees: self.build_attendees_array(mt, params[:account_email]),
              last_message_received_at: self.build_last_message_received_at(mt).to_s,
          }
      }
    end

    aborted_mts = self.get_threads_coming_from_scheduling(params[:window_start_time], params[:window_end_time], {
        account_email: params[:account_email],
        sought_status: MessageClassification::THREAD_STATUS_SCHEDULING_ABORTED
    }).map do |mt|
      {
          account_email: params[:account_email],
          status: "aborted",
          subject: mt.computed_data_light[:summary],
          thread_subject: mt.subject,
          other: {
              id: mt.id,
              server_thread_id: mt.server_thread_id,
              last_message_received_at: self.build_last_message_received_at(mt).to_s,
              appointment_nature: mt.computed_data_light[:appointment_nature],
              attendees: self.build_attendees_array(mt, params[:account_email])
          }
      }
    end

    event_creation_mts = self.get_threads_coming_from_scheduling(params[:window_start_time], params[:window_end_time], {
        account_email: params[:account_email],
        sought_status: MessageClassification::THREAD_STATUS_EVENTS_CREATION,
        message_classif_thread_status_to_seek: [MessageClassification::ASK_CREATE_EVENT],
        dont_check_attendees_present: true
    })

    events_creation_data = event_creation_mts.map {|mt|
      julie_action = mt.messages.map(&:message_classifications).
          flatten.
          map(&:julie_action).
          select{|ja| ja.done && ja.action_nature == JulieAction::JD_ACTION_CREATE_EVENT}.
          sort_by(&:updated_at).
          last
      JSON.parse(julie_action.try(:events) || "[]").map { |ev| ev.symbolize_keys.merge({
                                                                                           messages_thread_id: mt.id,
                                                                                           messages_thread_subject: mt.subject,
                                                                                           server_thread_id: mt.server_thread_id,
                                                                                       }) }
    }.flatten.map { |event|
      {
          account_email: params[:account_email],
          status: "scheduled",
          thread_subject: event[:messages_thread_subject],
          other: {
              id: event[:messages_thread_id],
              server_thread_id: event[:server_thread_id],
              event: event,
              attendees: []
          }
      }
    }

    scheduling_mts = self.get_currently_scheduling_threads(params[:window_start_time], params[:window_end_time], {
                                                   account_email: params[:account_email]
                                               }).map do |mt|

      last_message_received_at = self.build_last_message_received_at(mt)
      computed_data_light = mt.computed_data_light
      attendees = self.build_attendees_array(mt, params[:account_email])

      # If the thread last message is less than 14 days olds we considere it is still scheduling
      # If not we consider it has been aborted
      {
          account_email: params[:account_email],
          status: "scheduling",
          subject: computed_data_light[:summary],
          thread_subject: mt.subject,
          other: {
              id: mt.id,
              server_thread_id: mt.server_thread_id,
              waiting_for: mt.current_status == MessageClassification::THREAD_STATUS_SCHEDULING_WAITING_FOR_CLIENT ? "client" : "contact",
              valid_suggestions_count: computed_data_light[:date_times].select { |dt|
                begin
                  DateTime.parse(dt['date']) > DateTime.now
                rescue
                  false
                end
              }.length,
              suggestions_count: computed_data_light[:date_times].length,
              appointment_nature: computed_data_light[:appointment_nature],
              attendees: attendees,
              last_message_received_at: last_message_received_at.to_s,
              follow_up_reminder_date: mt.follow_up_reminder_date ? mt.follow_up_reminder_date.to_s : nil
          }
      }
    end


    # scheduling_mts.each do |mt|
    #   last_message_received_at = self.build_last_message_received_at(mt)
    #   computed_data_light = mt.computed_data_light
    #   attendees = self.build_attendees_array(mt, params[:account_email])
    #
    #   # If the thread last message is less than 14 days olds we considere it is still scheduling
    #   # If not we consider it has been aborted
    #
    #
    #   if (params[:start_of_week] - last_message_received_at.to_datetime).to_i <= 14
    #     still_scheduling <<
    #       {
    #         account_email: params[:account_email],
    #         status: "scheduling",
    #         subject: computed_data_light[:summary],
    #         thread_subject: mt.subject,
    #         other: {
    #           id: mt.id,
    #           server_thread_id: mt.server_thread_id,
    #           waiting_for: mt.current_status == MessageClassification::THREAD_STATUS_SCHEDULING_WAITING_FOR_CLIENT ? "client" : "contact",
    #           valid_suggestions_count: computed_data_light[:date_times].select { |dt|
    #             begin
    #               DateTime.parse(dt['date']) > DateTime.now
    #             rescue
    #               false
    #             end
    #           }.length,
    #           suggestions_count: computed_data_light[:date_times].length,
    #           appointment_nature: computed_data_light[:appointment_nature],
    #           attendees: attendees,
    #           last_message_received_at: last_message_received_at.to_s,
    #           follow_up_reminder_date: mt.follow_up_reminder_date ? mt.follow_up_reminder_date.to_s : nil
    #         }
    #       }
    #   else
    #     aborted_scheduling <<
    #       {
    #         account_email: params[:account_email],
    #         status: "aborted",
    #         subject: computed_data_light[:summary],
    #         thread_subject: mt.subject,
    #         other: {
    #             id: mt.id,
    #             server_thread_id: mt.server_thread_id,
    #             last_message_received_at: last_message_received_at.to_s,
    #             appointment_nature: computed_data_light[:appointment_nature],
    #             attendees: attendees
    #         }
    #       }
    #   end
    # end

    # aborted_mts = self.get_messages_threads({
    #                                             account_email: params[:account_email],
    #                                             start_of_week: params[:start_of_week],
    #                                             thread_statuses: [MessageClassification::THREAD_STATUS_SCHEDULING_ABORTED]
    #                                         })

    scheduled_mts + events_creation_data + scheduling_mts + aborted_mts
  end
end