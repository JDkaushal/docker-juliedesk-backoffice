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

    make_call(date)
  end

  private

  def self.make_call(date)
    client = HTTPClient.new(default_header: {
                                "Authorization" => ENV['CONSCIENCE_API_KEY']
                            })
    client.ssl_config.verify_mode = 0
    url = "#{ENV['CONSCIENCE_API_BASE_PATH_V1']}/forecastemails/?date=#{date.strftime('%Y-%m-%d')}&duration=60"
    response = client.get(url)

    json_response = JSON.parse(response.body)

    json_response['forecast'].each do |datetime, count|
      AiEmailFlowForecast.find_or_create_by(datetime: datetime, count: count)
    end
  end
end
