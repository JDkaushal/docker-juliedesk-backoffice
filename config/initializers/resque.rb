require 'resque/server'

Resque.redis = RESQUE_REDIS
begin
  Resque.logger = Logger.new(Rails.root.join('log', "resque.#{Rails.env}.log"))
rescue 
end


Resque::Server.use(Rack::Auth::Basic) do |user, password|
  operator Operator.find_by(email: user, privilege: Operator::PRIVILEGE_ADMIN)
  operator && operator.password_correct?(password)
end