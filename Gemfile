source 'https://rubygems.org'

# Used to load .env file as environment variable when loading gemfile
begin
  File.read(ENV['ENV_FILE'] || ".env").scan(/^([[A-Z0-9]|_]+)\=?(.*)?$/).each do |env_variable|
    ENV[env_variable[0]] = env_variable[1]
  end
rescue Errno::ENOENT

end

# Bundle edge Rails instead: gem 'rails', github: 'rails/rails'
gem 'rails', '5.1.6.1'
ruby '2.6.1'

# Use postgresql as the database for Active Record
gem 'pg'
# Use SCSS for stylesheets
gem 'sass-rails', '~> 5.0.7'
gem "compass-rails", "~> 3.0.2"

gem 'webpacker', '3.2.1'

GAT = "https://#{ENV['GITHUB_ACCESS_TOKEN']}:x-oauth-basic@github.com/JulieDesk"
gem "jd_auth", '~> 1.0.7', git: "#{GAT}/jd_auth", tag: "v1.0.7"

gem 'jquery-rails'
gem 'jquery-ui-rails'

gem 'unicorn'

gem 'uglifier', '>= 1.3.0'

gem "pusher"
#gem "websocket-client-simple"
gem "faye"

#gem "mail", '2.6.3'
gem "mail", '2.7.0'

gem 'resque', "~> 1.26.0"

gem "stringex", :git => 'git://github.com/Fred-JulieDesk/stringex.git'
#gem "stringex", path: "../stringex"

gem 'whenever', :require => false

gem 'handlebars_assets'

gem "rack-timeout"
gem 'rack-cors', '~> 0.4.0', :require => 'rack/cors'

gem "redis"

gem "nokogiri"
gem "angularjs-rails"
# To use angular templates steamlessly
gem 'angular-rails-templates', '~> 1.0.2'


#gem "httpclient"
#gem "httpclient",    path: "../httpclient"
gem "http"
gem 'mixpanel-ruby'
gem 'simple_segment'

#gem "http", path: "../http"

group :production, :production_ey, :production_sg, :release do
  gem 'lograge'
end

group :development, :release do
  gem 'better_errors'
end

group :development do
  gem 'binding_of_caller'
  gem 'railroady'
  gem 'capistrano', '3.6.0'
  gem 'capistrano-rails'
  gem 'capistrano-rvm'
  gem 'byebug'
end

group :test, :development do
  # Allow to test easily Javascript, including Angular apps
  gem 'jasmine'
end

group :test do
  gem 'rspec-rails', '~> 3.0'
  gem 'rspec-collection_matchers'
  gem 'rails-controller-testing'
  gem 'factory_girl'
  gem 'database_cleaner'
  gem "webmock-rspec-helper"
  #Code test coverage tool https://github.com/colszowka/simplecov
  gem 'simplecov', :require => false
end

# We will load it manually in an initializer because we are using Rack::Deflater Middleware https://github.com/MiniProfiler/rack-mini-profiler#custom-middleware-ordering-required-if-using-rackdeflate-with-rails
gem 'rack-mini-profiler', require: false
gem 'flamegraph'
gem 'stackprof' # ruby 2.1+ only
gem 'memory_profiler'

#Color picker for rails
gem 'jquery-minicolors-rails'

# ALlow to make easy list presentation
gem "smart_listing"

# Allow to save Settings easily in DB
gem "rails-settings-cached"

# Expose the AWS SDK to ruby with a easy wrapper
gem 'aws-sdk', '~> 2'

# Allow to lock a Worker, executing only one instance of it at any given time, pushing back to queue others that would be otherwise executed
# Used for the ImportEmailsWorker, to prevent multiple paralleled treatments of same threads
gem 'resque-workers-lock'
gem 'resque-timeout'

gem 'icalendar'

#active record history
gem 'json-schema'
gem 'paper_trail'


#Error tracking
gem 'sentry-raven', '~> 2.7.4'
gem 'resque-sentry', '~> 1.2.0'

gem 'loofah'