require 'resque/server'

Resque.redis = RESQUE_REDIS
Resque.logger = Logger.new(Rails.root.join('log', "resque.#{Rails.env}.log"))
