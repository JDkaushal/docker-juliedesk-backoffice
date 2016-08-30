require 'resque/server'

Resque.redis = RESQUE_REDIS
begin
  Resque.logger = Logger.new(Rails.root.join('log', "resque.#{Rails.env}.log"))
rescue 
end
