class JulieAction < ActiveRecord::Base

  belongs_to :message_classification
  has_many :operator_actions, as: :target
  has_one :date_suggestions_comparison_review

  JD_ACTION_CREATE_EVENT             = "create_event"
  JD_ACTION_UPDATE_EVENT             = "update_event"
  JD_ACTION_CANCEL_EVENT             = "cancel_event"
  JD_ACTION_POSTPONE_EVENT           = "postpone_event"
  JD_ACTION_DELETE_EVENT             = "delete_event"
  JD_ACTION_SUGGEST_DATES            = "suggest_dates"
  JD_ACTION_CHECK_AVAILABILITIES     = "check_availabilities"
  JD_ACTION_QUESTION_CLIENT          = "question_client"
  JD_ACTION_SEND_INFO                = "send_info"
  JD_ACTION_SEND_CONFIRMATION        = "send_confirmation"
  JD_ACTION_SEND_TO_FOUNDERS         = "send_to_founders"
  JD_ACTION_CANCEL_MULTIPLE_EVENTS   = "cancel_multiple_events"
  JD_ACTION_POSTPONE_MULTIPLE_EVENTS = "postpone_multiple_events"
  JD_ACTION_FREE_ACTION              = "free_action"
  JD_ACTION_FORWARD_TO_SUPPORT       = "forward_to_support"

  JD_ACTION_ASSOCIATE_EVENT          = "associate_event"
  JD_ACTION_NOTHING_TO_DO            = "nothing_to_do"
  JD_ACTION_FORWARD_TO_CLIENT        = "forward_to_client"
  JD_ACTION_WAIT_FOR_CONTACT         = "wait_for_contact"
  JD_ACTION_FOLLOWUP_ON_WEEKLY_RECAP = "follow_up_on_weekly_recap"
  JD_ACTION_INVITATION_ALREADY_SENT  = "invitation_already_sent"

  JD_ACTION_FOLLOW_UP_CLIENT         = "follow_up_client"
  JD_ACTION_FOLLOW_UP_CONTACTS       = "follow_up_contacts"

  # Allow to delete avery event related informations from the julie action (used mostly to de-associate an event from a Thread)
  def clear_event_data
    self.update(event_id: nil, calendar_login_username: nil, calendar_id: nil)
  end

  def self.available_actions

    [
      JulieAction::JD_ACTION_SUGGEST_DATES,
      JulieAction::JD_ACTION_CHECK_AVAILABILITIES,
      JulieAction::JD_ACTION_SEND_INFO,
      JulieAction::JD_ACTION_SEND_CONFIRMATION,
      JulieAction::JD_ACTION_FREE_ACTION,
      JulieAction::JD_ACTION_CANCEL_EVENT,
      JulieAction::JD_ACTION_CREATE_EVENT,
      JulieAction::JD_ACTION_CANCEL_MULTIPLE_EVENTS,
      JulieAction::JD_ACTION_POSTPONE_MULTIPLE_EVENTS,
      JulieAction::JD_ACTION_FORWARD_TO_CLIENT,
      JulieAction::JD_ACTION_FORWARD_TO_SUPPORT,
      JulieAction::JD_ACTION_WAIT_FOR_CONTACT,
      JulieAction::JD_ACTION_FOLLOWUP_ON_WEEKLY_RECAP,
      JulieAction::JD_ACTION_INVITATION_ALREADY_SENT,
      JulieAction::JD_ACTION_FOLLOW_UP_CLIENT,
      JulieAction::JD_ACTION_FOLLOW_UP_CONTACTS
    ].freeze

  end

  def get_messages_thread_reminder_date
    case self.action_nature
      when JulieAction::JD_ACTION_SUGGEST_DATES
        get_suggested_dates_barycentre
      when JulieAction::JD_ACTION_FOLLOW_UP_CONTACTS
        get_suggested_dates_barycentre
      when JulieAction::JD_ACTION_CHECK_AVAILABILITIES
        get_suggested_dates_barycentre
      when JulieAction::JD_ACTION_WAIT_FOR_CONTACT
        Time.now + 3.days
      when JulieAction::JD_ACTION_FREE_ACTION
        Time.now + 3.days
      else
        nil
    end
  end

  def self.reassociate_events_to_calendar_server_if_possible(date, specific_ids = [])
    puts "Reassociating Julie Actions from #{date} | With specific ids: #{specific_ids}"

    if specific_ids.present?
      julie_actions_with_events = JulieAction.select(:id, :event_id, :events, :calendar_id).find(specific_ids)
    else
      julie_actions_with_events = JulieAction.select(:id, :event_id, :events, :calendar_id).where("event_id IS NOT NULL OR (events::text <> '[]'::text AND events IS NOT NULL)").where("created_at >= ?", date)
    end

    julie_actions_with_events_count = julie_actions_with_events.size

    puts "Found #{julie_actions_with_events_count} Julie Actions to process"

    ja_with_events_not_found = []
    successfully_updated_julie_actions = []

    iteration = 0
    julie_actions_with_events.each do |ja|
      puts "Processing #{iteration += 1}/#{julie_actions_with_events_count} Julie Action (id: #{ja.id})"
      current_ja_events = JSON.parse(ja.events)

      if current_ja_events.present?
        puts "Processing for multiple events"
        # Manually created events stored in the 'events' attribute of the Julie Action under the form [{"id"=>"fiejrfoierjforeijfoerij/freferf==", "event_url"=>"", "calendar_id"=>"test@gmail.com", "calendar_login_username"=>"julie.gates@croscon.com", "timezone_id"=>"America/New_York"}]
        events_ids = current_ja_events.map{|e| e['id']}

        if events_ids.any?{|e_id| !e_id.is_number?}
          puts "Will process"
          success = true
          events_ids.each_slice(3) do |events|
            # We don't check next events if previous ones where not found, as it will anyway overall fail
            if success
              response = CalendarServerInterface.new.build_request(:get_event, {provider_ids: events})
              if response['events_data'].present? && response['events_data'].size == events.size
                fetched_events = response['events_data']
                current_ja_events.select{|eve| events.include?(eve['id'])}.each do |ev|
                  fetched_event = fetched_events.find{|f_e| f_e['provider_id'] == ev['id']}
                  ev['id'] = fetched_event['id']
                  ev['calendar_id'] = fetched_event['calendar_id']
                end
              else
                success = false
              end
            end
          end

          if success
            puts "Events updated: #{current_ja_events.inspect}"
            JulieAction.update(ja.id, events: current_ja_events.to_json)
            successfully_updated_julie_actions.push(ja.id)
          else
            puts "Events not found"
            ja_with_events_not_found.push(ja.id)
          end
          # response = CalendarServerInterface.new.build_request(:get_event, {provider_ids: events_ids})
          # if response['events_data'].present? && response['events_data'].size == current_ja_events.size
          #   fetched_events = response['events_data']
          #   current_ja_events.each do |ev|
          #     fetched_event = fetched_events.find{|f_e| f_e['provider_id'] == ev['id']}
          #     ev['id'] = fetched_event['id']
          #     ev['calendar_id'] = fetched_event['calendar_id']
          #   end
          #   puts "Events updated: #{current_ja_events.inspect}"
          #   JulieAction.update(ja.id, events: current_ja_events)
          #   successfully_updated_julie_actions.push(ja.id)
          # else
          #   puts "Events not found"
          #   ja_with_events_not_found.push(ja.id)
          # end
        end
      else
        # Event created from an ask availabilities flow, stored in the 'event_id' and 'calendar_id' attributes of the Julie Action under the form event_id: "fiejrfoierjforeijfoerij/freferf==" and calendar_id: "test@gmail.com"
        event_id = ja.event_id
        puts "Processing for single event: #{event_id}"
        unless event_id.is_number?
          puts "Will process"
          response = CalendarServerInterface.new.build_request(:get_event, {provider_ids: [event_id]})

          if response['events_data'].present?
            fetched_event = response['events_data'].first
            # Cannot update a record when it was retrieved with a select it seems
            puts "Event found: #{fetched_event.inspect}"
            JulieAction.update(ja.id, event_id: fetched_event['id'], calendar_id: fetched_event['calendar_id'])
            successfully_updated_julie_actions.push(ja.id)
          else
            puts "Event not found"
            ja_with_events_not_found.push(ja.id)
          end
        end
      end
    end


    {
        ja_with_events_not_found: ja_with_events_not_found,
        successfully_updated_julie_actions: successfully_updated_julie_actions

    }
  end

  def event_data
    message.messages_thread.event_data
  end

  def account
    message.messages_thread.account
  end

  def send_suggestions_email event_data

  end

  def send_question_to_client event_data

  end

  def send_info event_data

  end

  def send_to_founders event_data

  end

  def initial_recipients
    result = self.message_classification.message.initial_recipients(only_reply_all: self.message_classification.classification != MessageClassification::ASK_DATE_SUGGESTIONS)
    if self.action_nature == JulieAction::JD_ACTION_FORWARD_TO_SUPPORT
      result[:cc] << 'hello@juliedesk.com'
    end

    result
  end

  private

  def get_suggested_dates_barycentre
    # When there are no date_times proposed, it means it was an event creation
    # So we will not set a reminder
    if self.date_times == "[]"
      self.action_nature == JulieAction::JD_ACTION_CHECK_AVAILABILITIES ? nil : Time.now + 3.days
    else
      parsed_dates = JSON.parse(self.date_times).map{|d| d['date']}
      barycentre = DateTime.parse(parsed_dates.shift)
      now = Time.now

      parsed_dates.push(now.to_s)

      if parsed_dates.size > 0
        parsed_dates.each do |date|
          date = DateTime.parse(date)
          barycentre = barycentre + (get_hours_diff(barycentre, date) / 2).hours
        end
      end

      #barycentre.change(hour: 10, min: 10)
      barycentre
    end
  end

  def get_days_diff(date1, date2)
    (date2 - date1).to_i
  end

  def get_hours_diff(date1, date2)
    ((date2.to_time - date1.to_time)/1.hour).round
  end
end