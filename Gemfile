source 'https://rubygems.org'


# Bundle edge Rails instead: gem 'rails', github: 'rails/rails'
gem 'rails', '4.1.6'
ruby '2.2.0'
# Use postgresql as the database for Active Record
gem 'pg'
# Use SCSS for stylesheets
gem 'sass-rails', '~> 4.0.3'
gem "compass-rails", "~> 1.1.2"


gem 'jquery-rails'
gem 'jquery-ui-rails'

gem 'unicorn'

gem 'uglifier', '>= 1.3.0'

gem 'newrelic_rpm'

gem "pusher"

gem "mail", '2.6.3'

gem "stringex", :git => 'git://github.com/Fred-JulieDesk/stringex.git'

gem 'delayed_job_active_record'

gem "detect_language"

gem 'handlebars_assets'

gem "rack-timeout"
gem 'rack-cors', :require => 'rack/cors'

gem "redis"

gem "nokogiri"
gem "angularjs-rails"
# To use angular templates steamlessly
gem 'angular-rails-templates'

gem "httpclient"

group :production do
  gem 'lograge'
end

group :development do
  gem 'better_errors'
  gem 'binding_of_caller'
end

group :test, :development do
  # Allow to test easily Javascript, including Angular apps
  gem 'jasmine'
end

group :test do
  gem 'rspec-rails', '~> 3.0'
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