class JulieActionsController < ApplicationController

  include ProfilerHelper

  before_action :check_staging_mode

  def show
    @julie_action = JulieAction.find params[:id]
    @message_classification = @julie_action.message_classification
    @message = @message_classification.message

    @accounts_cache_light = Account.accounts_cache(mode: "light")
    @julie_emails = JulieAlias.all.map(&:email).map(&:downcase)
    @client_emails = @accounts_cache_light.map{|k, account| [account['email']] + account['email_aliases']}.flatten.map(&:downcase)

    OperatorAction.create_and_verify({
                                         initiated_at: DateTime.now,
                                         target: @julie_action,
                                         nature: OperatorAction::NATURE_OPEN,
                                         operator_id: session[:operator_id],
                                         messages_thread_id: @message.messages_thread_id
                                     })

    @messages_thread = MessagesThread.includes(messages: {message_classifications: :julie_action, message_interpretations: {}}).find(@message.messages_thread_id)
    @messages_thread.re_import

    @message = @messages_thread.messages.select{|m| m.id == @message.id}.first

    if @julie_action.action_nature == JulieAction::JD_ACTION_SUGGEST_DATES
      @first_date_suggestion = !@messages_thread.has_already_processed_action_once(MessageClassification::ASK_DATE_SUGGESTIONS)
    end

    @is_discussion_client_julie_only = @message.is_discussion_client_julie_only
  end

  def update
    print_time "init"
    julie_action = JulieAction.includes(:message_classification).find(params[:id])
    print_time "Find Julie Action"

    print_time "Update messages thread"

    message_classification_params_to_update = {}

    if params[:timezone].present?
      message_classification_params_to_update[:timezone] = params[:timezone]
      #julie_action.message_classification.update(timezone: params[:timezone])
    end

    date_times = []
    if params[:date_times]
      message_classification_timezone = julie_action.message_classification.timezone

      date_times = params[:date_times].map{|dt|
        {
            timezone: message_classification_timezone,
            date: DateTime.parse(dt).utc.to_s
        }
      }
    end
    print_time "Computing date times"



    julie_action.update_attributes({
        text: params[:text],
        generated_text: params[:generated_text],
        date_times: date_times.to_json,
        event_id: params[:event_id] || julie_action.event_id,
        event_url: params[:event_url] || julie_action.event_url,
        calendar_id: params[:calendar_id] || julie_action.calendar_id,
        calendar_login_username: params[:calendar_login_username] || julie_action.calendar_login_username,
        done: params[:done].present?,
        events: (params[:events].try(:values) || []).to_json,
        processed_in: params[:processed_in],
        deleted_event: params[:deleted_event],
        event_from_invitation: params[:event_from_invitation],
        event_from_invitation_organizer: params[:event_from_invitation_organizer],
     })
    print_time "Updating julie action"

    if params[:messages_thread_id].present?
      data = {last_operator_id: session[:operator_id]}

      if params[:deleted_event] == 'true'
        data.merge!(event_booked_date: nil)
      else
        if params[:event_booked_date].present?
          data.merge!(event_booked_date: DateTime.parse(params[:event_booked_date]))
        end
      end

      messages_thread = MessagesThread.find(params[:messages_thread_id])

      begin
      if params[:event_id].present? && !julie_action.event_id

        ClientSuccessTrackingHelpers.async_track("new_event", messages_thread.account_email, {
            bo_thread_id: messages_thread.id,
            thread_messages_count: messages_thread.messages.count,
            thread_status: messages_thread.status,
            bo_message_id: julie_action.message_classification.message_id,
            current_classificatio: julie_action.message_classification.classification,
            first_time: messages_thread.messages.map(&:message_classifications).flatten.empty?,
            new_email_received_at: julie_action.message_classification.message.created_at.strftime("%Y-%m-%dT%H:%M:%S")
        })
      end
      rescue
      end

      # We don't update the reminder date if the event has already been scheduled
      if params[:client_settings] && params[:client_settings][:auto_follow_up] == 'true' && messages_thread.status != MessageClassification::THREAD_STATUS_SCHEDULED
        new_reminder = julie_action.get_messages_thread_reminder_date

        if messages_thread.follow_up_reminder_date.present?
          # We only replace the reminder date if the new one is sooner than the old one or if it is nil
          if messages_thread.follow_up_reminder_date.nil? || new_reminder.nil? || new_reminder < messages_thread.follow_up_reminder_date
            data.merge!(follow_up_reminder_date: new_reminder)
          end
        else
          # When no reminder date has been set on the thread, we will anyway replace it with the new_reminder, even if he is nil again
          data.merge!(follow_up_reminder_date: new_reminder)
        end
      end

      messages_thread.update(data)
    end

    if params[:call_instructions].present?
      message_classification_params_to_update[:call_instructions] = params[:call_instructions].to_json

      #julie_action.message_classification.update(call_instructions: params[:call_instructions].to_json)
    end

    if params[:using_meeting_room].present?
      message_classification_params_to_update[:using_meeting_room] = params[:using_meeting_room]
      message_classification_params_to_update[:meeting_room_details] = params[:meeting_room_details]

      #julie_action.message_classification.update(using_meeting_room: params[:using_meeting_room], meeting_room_details: params[:meeting_room_details])
    end

    if params[:notes_updated].present?
      message_classification_params_to_update[:notes] = params[:notes_updated]
    end

    if params[:virtual_resource_used].present?
      if params[:virtual_resource_used] == 'undefined'
        message_classification_params_to_update[:virtual_resource_used] = nil
      else
        message_classification_params_to_update[:virtual_resource_used] = params[:virtual_resource_used]
      end
    end

    if message_classification_params_to_update.present?
      julie_action.message_classification.update(message_classification_params_to_update)
    end


    print_time "Updating message classification"

    render json: {
        status: "success",
        message: "",
        data: {

        }
    }

    print_time "Rendering view"

    print_all_times
  end
end