class Ai::DatesVerificationController < ApplicationController

  def verify_dates
    render json: AiProxy.new.build_request(:verify_dates, params)
    rescue Timeout::Error
      render json: { error_code: "AI_TIMEOUT", message: "Timeout error" }, status: :request_timeout
  end
end