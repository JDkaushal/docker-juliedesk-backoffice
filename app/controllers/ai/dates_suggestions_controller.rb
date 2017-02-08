class Ai::DatesSuggestionsController < ApplicationController

  def fetch
    render json: AiProxy.new.build_request(:fetch_dates_suggestions, params)
    rescue Timeout::Error
  render json: { error_code: "AI:TIMEOUT", message: "Timeout error" }, status: :request_timeout
  end

  def send_learning_data
    render json: AiProxy.new.build_request(:send_dates_suggestions_learning_data, params)
    rescue Timeout::Error
      render json: { error_code: "AI:TIMEOUT", message: "Timeout error" }, status: :request_timeout
  end

end