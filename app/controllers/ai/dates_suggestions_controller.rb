class Ai::DatesSuggestionsController < ApplicationController

  def fetch
    render json: AiProxy.new.build_request(:fetch_dates_suggestions, params)
    #render json: ['2016-10-19T00:00:00+0000']
  end

  def send_learning_data
    render json: AiProxy.new.build_request(:send_dates_suggestions_learning_data, params)
  end

end