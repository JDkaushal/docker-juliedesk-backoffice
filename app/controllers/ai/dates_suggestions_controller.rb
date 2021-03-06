class Ai::DatesSuggestionsController < ApplicationController

  def fetch
    JuliedeskTrackerInterface.new.build_request(:track, {name: 'Auto_suggestions_tracking', date:  Time.now.to_s, properties: {step: 'date_suggestions#fetch:initiated', julie_action_id: params[:julie_action_id]}, distinct_id: params[:julie_action_id]})

    if params[:compute_linked_attendees]
      messages_thread = Message.find(params[:message_id]).messages_thread
      messages_thread.check_recompute_linked_attendees(params[:old_attendees], params[:attendees])
      params[:thread_data][:linked_attendees] = messages_thread.linked_attendees
    end

    json = AI_PROXY_INTERFACE.build_request(:fetch_dates_suggestions, params)

    if json[:error]
      Raven.capture_exception(StandardError.new("Error while fetching date suggestions for message id #{params[:message_id]}"))
    end

    JuliedeskTrackerInterface.new.build_request(:track, {name: 'Auto_suggestions_tracking', date:  Time.now.to_s, properties: {step: 'date_suggestions#fetch:done', julie_action_id: params[:julie_action_id]}, distinct_id: params[:julie_action_id]})

    render json: json
    #render json: {"status":"success","timezone":"Europe/Berlin","algo_duration":2,"suggested_dates":["2017-02-20T10:00:00+0000","2017-02-20T13:00:00+0000","2017-02-20T15:00:00+0000","2017-02-20T17:00:00+0000"],"suggested_dates_id":8164}
  rescue AiProxy::TimeoutError
      render json: { error_code: "AI:TIMEOUT", message: "Timeout error" }, status: :request_timeout
  end

  def puts_calendar_in_conscience_cache
    if params[:compute_linked_attendees]
      messages_thread = Message.find(params[:message_id]).messages_thread
      messages_thread.check_recompute_linked_attendees(params[:old_attendees], params[:attendees])
      params[:thread_data][:linked_attendees] = messages_thread.linked_attendees
    end

    json = AI_PROXY_INTERFACE.build_request(:puts_calendar_in_conscience_cache, params)

    render json: json
  end

  def send_learning_data
    render json: AI_PROXY_INTERFACE.build_request(:send_dates_suggestions_learning_data, params)
  rescue AiProxy::TimeoutError
      render json: { error_code: "AI:TIMEOUT", message: "Timeout error" }, status: :request_timeout
  end

  def dates_suggestions_auto_process_update
    render json: AI_PROXY_INTERFACE.build_request(:dates_suggestions_auto_process_update, params)
  rescue AiProxy::TimeoutError
    render json: { error_code: "AI:TIMEOUT", message: "Timeout error" }, status: :request_timeout
  end
end