class AiEmailFlowForecast < ActiveRecord::Base

  validates_uniqueness_of :datetime

  def as_json(value)
    {
        datetime: self.datetime.strftime('%Y-%m-%d %H:%M:%S'),
        count: self.count
    }
  end

  def self.fetch(date = nil)

      unless date.present?
        date = AiEmailFlowForecast.all.order(datetime: :desc).limit(1).first.try(:datetime)

        unless date.present?
          date = DateTime.now
        end
      end

    make_call(date, ENV['AI_FORECAST_PROJECTION_DURATION_IN_DAYS'])
  end

  def self.handle_forecast_data(data)
    forecasts = {}
    datetime_format = '%Y-%m-%d %H:%M:%S'
    forecast_datetimes = data.keys
    existing_forecasts_datetimes = []
    forecasts_to_insert = []

    existing_forecasts =  AiEmailFlowForecast.where(datetime: forecast_datetimes)

    existing_forecasts.each do |forecast|
      current_forecast_datetime = forecast.datetime.strftime(datetime_format)
      forecast.update(count: data[current_forecast_datetime])

      existing_forecasts_datetimes << current_forecast_datetime

      forecasts[current_forecast_datetime] = forecast.count
    end

    forecast_datetimes -= existing_forecasts_datetimes


    forecast_datetimes.each do |forecast_datetime|
      current_count = data[forecast_datetime]
      forecasts_to_insert << "(#{current_count}, '#{forecast_datetime}')"
      #new_forecast = AiEmailFlowForecast.create(datetime: forecast_datetime, count: data[forecast_datetime])
      forecasts[forecast_datetime] = current_count
    end

    if forecasts_to_insert.size > 0
      sql = "INSERT INTO ai_email_flow_forecasts (\"count\", \"datetime\") VALUES #{forecasts_to_insert.join(", ")}"

      ActiveRecord::Base.connection.execute(sql)
    end



    # data.each do |datetime, count|
    #   if forecast = AiEmailFlowForecast.find_by(datetime: datetime)
    #     forecast.update(count: count)
    #   else
    #     forecast = AiEmailFlowForecast.create(datetime: datetime, count: count)
    #   end
    #
    #   forecasts[forecast.datetime.strftime(datetime_format)] = forecast.count
    # end

    forecasts
  end

  private

  def self.make_call(date, duration)
    client = HTTPClient.new(default_header: {
                                "Authorization" => ENV['CONSCIENCE_API_KEY']
                            })
    client.ssl_config.verify_mode = 0
    url = "#{ENV['CONSCIENCE_API_BASE_PATH_V1']}/forecastemails/?date=#{date.strftime('%Y-%m-%d')}&duration=#{duration}"
    response = client.get(url)

    json_response = JSON.parse(response.body)

    self.handle_forecast_data(json_response['forecast'])

    # json_response['forecast'].each do |datetime, count|
    #   if forecast = AiEmailFlowForecast.find_by(datetime: datetime)
    #     forecast.update(count: count)
    #   else
    #     AiEmailFlowForecast.create(datetime: datetime, count: count)
    #   end
    # end
  end
end
