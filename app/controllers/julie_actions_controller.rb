class JulieActionsController < ApplicationController

  def show
    @julie_action = JulieAction.find params[:id]
    puts @julie_action.inspect
    @message = @julie_action.message_classification.message

    @client_emails = Account.accounts_cache(mode: "light").map{|k, account| [account['email']] + account['email_aliases']}.flatten

    OperatorAction.create_and_verify({
                                         initiated_at: DateTime.now,
                                         target: @julie_action,
                                         nature: OperatorAction::NATURE_OPEN,
                                         operator_id: session[:operator_id],
                                         messages_thread_id: @message.messages_thread_id
                                     })

    @messages_thread = MessagesThread.includes(messages: {message_classifications: :julie_action}).find(@message.messages_thread_id)
    @messages_thread.re_import
    @message = @messages_thread.messages.select{|m| m.id == @message.id}.first

    @is_discussion_client_julie_only = @message.is_discussion_client_julie_only
  end

  def update
    julie_action = JulieAction.find params[:id]


    date_times = []
    if params[:date_times]
      date_times = params[:date_times].map{|dt|
        {
            timezone: julie_action.message_classification.timezone,
            date: DateTime.parse(dt).utc.to_s
        }
      }
    end
    julie_action.update_attributes({
        text: params[:text],
        date_times: date_times.to_json,
        event_id: params[:event_id] || julie_action.event_id,
        event_url: params[:event_url] || julie_action.event_url,
        calendar_id: params[:calendar_id] || julie_action.calendar_id,
        calendar_login_username: params[:calendar_login_username] || julie_action.calendar_login_username,
        done: params[:done].present?,
        events: (params[:events].try(:values) || []).to_json,
        processed_in: params[:processed_in],
        deleted_event: params[:deleted_event]
     })

    if params[:call_instructions].present?
      julie_action.message_classification.update(call_instructions: params[:call_instructions].to_json)
    end

    render json: {
        status: "success",
        message: "",
        data: {

        }
    }
  end
end