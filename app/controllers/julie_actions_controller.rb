class JulieActionsController < ApplicationController

  include ProfilerHelper
  include FlowConditionsHelper

  before_action :check_staging_mode

  def show


    begin
      @julie_action = JulieAction.find params[:id]
    rescue ActiveRecord::RecordNotFound
      render status: :not_found, text: 'Sorry, this action does not exist.'
      return
    end

    JuliedeskTrackerInterface.new.build_request(:track, {name: 'Auto_suggestions_tracking', date:  Time.now.to_s, properties: {step: 'julie_actions#show:initiated', julie_action_id: @julie_action.id}, distinct_id: @julie_action.id})

    @message_classification = @julie_action.message_classification
    @message = @message_classification.message

    @accounts_cache_light = Account.accounts_cache(mode: "light")
    @julie_emails = JulieAlias.all.map(&:email).map(&:downcase)
    @client_emails = @accounts_cache_light.select { |_, account| account['subscribed'] && account['configured'] }.map{|_, account| [account['email']] + account['email_aliases']}.flatten.map(&:downcase)

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

    @is_first_date_suggestion = @julie_action.action_nature == JulieAction::JD_ACTION_SUGGEST_DATES &&
        !@messages_thread.has_already_processed_action_once(MessageClassification::ASK_DATE_SUGGESTIONS)

    JuliedeskTrackerInterface.new.build_request(:track, {name: 'Auto_suggestions_tracking', date:  Time.now.to_s, properties: {step: 'julie_actions#show:database_loaded', julie_action_id: @julie_action.id}, distinct_id: @julie_action.id})

    @flow_conditions = handle_flow_conditions({
                                                  julie_action: @julie_action,
                                                  messages_thread: @messages_thread
                                              }, {
        trust_julia_suggestions_virtual_from_backend: {
            label: 'We can trust Jul.IA date suggestions for virtual appointments - from Backend',
            back_conditions: {
                features_active: {
                    Feature::FEATURE_TRUST_JULIA_SUGGESTION => true,
                    Feature::FEATURE_AUTO_DATE_SUGGESTIONS_FROM_BACKEND => true
                },
                action_nature: JulieAction::JD_ACTION_SUGGEST_DATES,
                event_type: MessageClassification::VIRTUAL_EVENT_TYPES,
                should_book_resource: false,
                current_notes_present: false,
                #free_notes_present: false,
                #linked_attendees_present: false,
                all_clients_on_calendar_server: true,
                #main_client_auto_date_suggestions_on: true,
                constraints_conflicts: false,
                client_on_trip: false,
                date_times_from_ai_count: 3
            },
            front_conditions: {
            }
        },
        trust_julia_suggestions_physical_from_backend: {
            label: 'We can trust Jul.IA date suggestions for physical appointments - from Backend',
            back_conditions: {
                features_active: {
                    Feature::FEATURE_TRUST_JULIA_SUGGESTION => true,
                    Feature::FEATURE_AUTO_DATE_SUGGESTIONS_FROM_BACKEND => true
                },
                action_nature: JulieAction::JD_ACTION_SUGGEST_DATES,
                event_type: MessageClassification::PHYSICAL_EVENT_TYPES,
                should_book_resource: false,
                current_notes_present: false,
                #free_notes_present: false,
                #linked_attendees_present: false,
                all_clients_on_calendar_server: true,
                #main_client_auto_date_suggestions_on: true,
                constraints_conflicts: false,
                client_on_trip: false,
                date_times_from_ai_count: 3,
                date_times_from_ai_on_all_day_event: false
            },
            front_conditions: {

            }
        },
        trust_julia_suggestions_virtual: {
            label: 'We can trust Jul.IA date suggestions for virtual appointments',
            back_conditions: {
                features_active: {
                    Feature::FEATURE_TRUST_JULIA_SUGGESTION => true,
                    Feature::FEATURE_AUTO_DATE_SUGGESTIONS_FROM_BACKEND => false
                },
                action_nature: JulieAction::JD_ACTION_SUGGEST_DATES,
                event_type: MessageClassification::VIRTUAL_EVENT_TYPES,
                should_book_resource: false,
                current_notes_present: false,
                #free_notes_present: false,
                #linked_attendees_present: false,
                all_clients_on_calendar_server: true,
                #main_client_auto_date_suggestions_on: true,
                constraints_conflicts: false,
                client_on_trip: false,
                date_times_from_ai_count: 0
            },
            front_conditions: {
                conscience_suggestion: {
                    count: 4#,
                    #suggestion_on_all_day_event: false
                }
            },
            flow_action: 'autoProcessDateSuggestions'
        },
        trust_julia_suggestions_physical: {
            label: 'We can trust Jul.IA date suggestions for physical appointments',
            back_conditions: {
                features_active: {
                    Feature::FEATURE_TRUST_JULIA_SUGGESTION => true,
                    Feature::FEATURE_AUTO_DATE_SUGGESTIONS_FROM_BACKEND => false
                },
                action_nature: JulieAction::JD_ACTION_SUGGEST_DATES,
                event_type: MessageClassification::PHYSICAL_EVENT_TYPES,
                should_book_resource: false,
                current_notes_present: false,
                #free_notes_present: false,
                #linked_attendees_present: false,
                all_clients_on_calendar_server: true,
                #main_client_auto_date_suggestions_on: true,
                constraints_conflicts: false,
                client_on_trip: false,
                date_times_from_ai_count: 0
            },
            front_conditions: {
                conscience_suggestion: {
                    count: 4,
                    suggestion_on_all_day_event: false
                }
            },
            flow_action: 'autoProcessDateSuggestions'
        }
    })


    @is_discussion_client_julie_only = @message.is_discussion_client_julie_only

    if (@flow_conditions.keys & [:trust_julia_suggestions_virtual_from_backend, :trust_julia_suggestions_physical_from_backend]).length > 0
      @julie_action.update(date_suggestions_full_ai_capacity: true)

      JuliedeskTrackerInterface.new.build_request(:track, {name: 'Auto_suggestions_tracking', date:  Time.now.to_s, properties: {step: 'julie_actions#show:done', julie_action_id: @julie_action.id}, distinct_id: @julie_action.id})
      # Throw the dice to know if we help operator with AI or not
      should_help_with_ai = true#rand >= 0.5

      @julie_action.update(date_suggestions_full_ai: should_help_with_ai)
    end
  end

  def update
    julie_action = JulieAction.includes(:message_classification).find(params[:id])
    message_classification_params_to_update = {}

    if params[:timezone].present?
      message_classification_params_to_update[:timezone] = params[:timezone]
      #julie_action.message_classification.update(timezone: params[:timezone])
    end

    date_times = []
    if params[:date_times] && params[:date_times].is_a?(Array)
      message_classification_timezone = julie_action.message_classification.timezone

      date_times = params[:date_times].map{|dt|
        {
            timezone: message_classification_params_to_update[:timezone] || message_classification_timezone,
            date: DateTime.parse(dt).utc.to_s
        }
      }
    end

    # begin
    #   if params[:event_id].present? && !julie_action.event_id
    #
    #     messages_thread = julie_action.message_classification.message.messages_thread
    #     ClientSuccessTrackingHelpers.async_track("Event Was Created", messages_thread.account_email, {
    #         bo_thread_id: messages_thread.id,
    #         thread_messages_count: messages_thread.messages.count,
    #         thread_status: messages_thread.status,
    #         bo_message_id: julie_action.message_classification.message_id,
    #         current_classification: julie_action.message_classification.classification,
    #         first_time: messages_thread.messages.map(&:message_classifications).flatten.empty?,
    #         new_email_received_date: julie_action.message_classification.message.created_at.strftime("%Y-%m-%dT%H:%M:%S")
    #     })
    #   end
    # rescue
    # end

    if params[:selectingOccurrence] && params[:event_id].to_s.include?('__')
      created_occurrence_in_db = PostponeEvents::OccurrenceCreator.new({event_id: params[:event_id], start_date: params[:start_date], end_date: params[:end_date]}).create

      if created_occurrence_in_db.present? && created_occurrence_in_db['event_id'].present?
        params[:event_id] = created_occurrence_in_db['event_id']
      end
    end

    if params[:ai_call_status]
      current_julie_action_ai_call_status = julie_action.ai_call_status || {}
      current_julie_action_ai_call_status = current_julie_action_ai_call_status.dup
      current_julie_action_ai_call_status.merge!(params[:ai_call_status])
    end

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
        date_suggestions_full_ai: params[:date_suggestions_full_ai] == 'true',
        ai_call_status: current_julie_action_ai_call_status
     })

    if julie_action.date_suggestions_full_ai
      DateSuggestionsReview.generate_from_julie_action(julie_action.id)
    end

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
    end

    if params[:booked_rooms_details].present?
      message_classification_params_to_update[:booked_rooms_details] = params[:booked_rooms_details].to_json
    end

    if params[:meeting_room_details].present?
      message_classification_params_to_update[:meeting_room_details] = params[:meeting_room_details].to_json
    end

    if params[:using_meeting_room].present?
      message_classification_params_to_update[:using_meeting_room] = params[:using_meeting_room]
      message_classification_params_to_update[:meeting_room_details] = params[:meeting_room_details]
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

    if params[:annotated_reply].present?
      message_classification_params_to_update[:annotated_reply] = params[:annotated_reply]
    end

    if message_classification_params_to_update.present?
      julie_action.message_classification.update(message_classification_params_to_update)
    end

    render json: {
        status: "success",
        message: "",
        data: {

        }
    }
  end
end