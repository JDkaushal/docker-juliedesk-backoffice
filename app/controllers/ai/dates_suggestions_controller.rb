class Ai::DatesSuggestionsController < ApplicationController

  def fetch
    render json: AI_PROXY_INTERFACE.build_request(:fetch_dates_suggestions, params)
    #render json: {"status":"success","timezone":"Europe/Berlin","algo_duration":2,"suggested_dates":["2017-02-20T10:00:00+0000","2017-02-20T13:00:00+0000","2017-02-20T15:00:00+0000","2017-02-20T17:00:00+0000"],"suggested_dates_id":8164}
  rescue AiProxy::TimeoutError
      render json: { error_code: "AI:TIMEOUT", message: "Timeout error" }, status: :request_timeout
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