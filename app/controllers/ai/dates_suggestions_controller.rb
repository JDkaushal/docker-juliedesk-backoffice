class Ai::DatesSuggestionsController < ApplicationController

  def fetch
    render json: AiProxy.new.build_request(:fetch_dates_suggestions, params)
    #render json: {"status":"success","timezone":"Europe/Berlin","algo_duration":2,"suggested_dates":["2017-02-19T10:00:00+0000","2017-02-19T13:00:00+0000","2017-02-19T15:00:00+0000","2017-02-19T17:00:00+0000"],"suggested_dates_id":8164}
    rescue Timeout::Error
      render json: { error_code: "AI:TIMEOUT", message: "Timeout error" }, status: :request_timeout
  end

  def send_learning_data
    render json: AiProxy.new.build_request(:send_dates_suggestions_learning_data, params)
    rescue Timeout::Error
      render json: { error_code: "AI:TIMEOUT", message: "Timeout error" }, status: :request_timeout
  end

end