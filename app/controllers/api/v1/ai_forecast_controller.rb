class Api::V1::AiForecastController < Api::ApiV1Controller

  def emails
    start_date = DateTime.parse(params[:start_date])
    end_date = start_date + params[:duration].to_i.days

    forecast = AiEmailFlowForecast.where('datetime >= ? AND datetime <= ?', start_date, end_date)
    result = {}

    if forecast.present?
      forecast.each do |f|
        result[f.datetime.strftime('%Y-%m-%d %H:%M:%S')] = f.count
      end
    else
      AiEmailFlowForecast.fetch(start_date)

      forecast = AiEmailFlowForecast.where('datetime >= ? AND datetime <= ?', start_date, end_date)

      forecast.each do |f|
        result[f.datetime.strftime('%Y-%m-%d %H:%M:%S')] = f.count
      end
    end

    render json: result
  end
end