class Ai::DatesVerificationController < ApplicationController

  def verify_dates

    #message = Message.find(params.delete(:message_id))
    #result = AiProxy.new.build_request(:verify_dates, params)

    #message.message_interpretations.create(question: :, raw_response: result.to_json)

    render json: AiProxy.new.build_request(:verify_dates, params)
  end
end