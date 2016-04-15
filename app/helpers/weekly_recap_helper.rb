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
        #where(messages_threads: {account_email: params[:account_email]}).
        where(message_classifications: {thread_status: params[:thread_statuses]}).
        where("message_classifications.created_at >= ?", params[:start_of_week]).
        distinct.
        includes(messages: {message_classifications: :julie_action})

    messages_threads = messages_threads.select { |mt|
      mt.account_email == params[:account_email] ||
          mt.computed_data_only_attendees[:attendees].find{|att| att['account_email'] == params[:account_email]}
    }

    messages_threads.select { |mt|
      status_before_this_week = mt.messages.map(&:message_classifications).flatten.select { |mc| mc.created_at < params[:start_of_week] }.sort_by(&:created_at).map(&:thread_status).last
      params[:thread_statuses].include?(mt.current_status) &&
          (status_before_this_week.nil? || status_before_this_week != mt.current_status || params[:dont_check_status_has_changed_this_week]) &&
          (mt.computed_data_light[:attendees].length > 0 || params[:dont_check_attendees_present]) &&
          mt.messages.select { |m| !m.from_me }.length > 0
    }
  end

  # Returns the date of the last message received as string
  def self.build_last_message_received_at mt
    mt.messages.select { |m| !m.from_me }.map(&:received_at).max.to_s
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
      JSON.parse(julie_action.try(:events) || "[]").map { |ev| ev.symbolize_keys.merge({messages_thread_id: mt.id}) }
    }.flatten

    scheduling_mts = self.get_messages_threads({
                                                   account_email: params[:account_email],
                                                   start_of_week: params[:start_of_week] - 1.weeks,
                                                   thread_statuses: [MessageClassification::THREAD_STATUS_SCHEDULING_WAITING_FOR_CLIENT, MessageClassification::THREAD_STATUS_SCHEDULING_WAITING_FOR_CONTACT],
                                                   dont_check_status_has_changed_this_week: true
                                               })

    scheduling_aborted_mts = self.get_messages_threads({
                                                           account_email: params[:account_email],
                                                           start_of_week: params[:start_of_week] - 3.weeks,
                                                           thread_statuses: [MessageClassification::THREAD_STATUS_SCHEDULING_WAITING_FOR_CLIENT, MessageClassification::THREAD_STATUS_SCHEDULING_WAITING_FOR_CONTACT],
                                                           dont_check_status_has_changed_this_week: true
                                                       }) - scheduling_mts

    aborted_mts = self.get_messages_threads({
                                                account_email: params[:account_email],
                                                start_of_week: params[:start_of_week],
                                                thread_statuses: [MessageClassification::THREAD_STATUS_SCHEDULING_ABORTED]
                                            })


    scheduled_mts.map { |mt|
      {
          status: "scheduled",
          subject: mt.computed_data_light[:summary],
          other: {
              id: mt.id,
              event: mt.event_data,
              last_message_received_at: self.build_last_message_received_at(mt)
          }
      }
    } + events_creation_data.map { |event|
      {
          status: "scheduled",
          other: {
              id: event[:messages_thread_id],
              event: event
          }
      }
    } + scheduling_mts.map { |mt|
      {
          status: "scheduling",
          subject: mt.computed_data_light[:summary],
          other: {
              id: mt.id,
              waiting_for: mt.current_status == MessageClassification::THREAD_STATUS_SCHEDULING_WAITING_FOR_CLIENT ? "client" : "contact",
              valid_suggestions_count: mt.computed_data_light[:date_times].select { |dt|
                begin
                  DateTime.parse(dt['date']) > DateTime.now
                rescue
                  false
                end
              }.length,
              suggestions_count: mt.computed_data_light[:date_times].length,
              appointment_nature: mt.computed_data_light[:appointment_nature],
              attendees: self.build_attendees_array(mt, params[:account_email]),
              last_message_received_at: self.build_last_message_received_at(mt)
          }
      }
    } + (aborted_mts + scheduling_aborted_mts).map { |mt|
      {
          status: "aborted",
          subject: mt.computed_data_light[:summary],
          other: {
              id: mt.id,
              last_message_received_at: self.build_last_message_received_at(mt),
              appointment_nature: mt.computed_data_light[:appointment_nature],
              attendees: self.build_attendees_array(mt, params[:account_email])
          }
      }
    }
  end
end