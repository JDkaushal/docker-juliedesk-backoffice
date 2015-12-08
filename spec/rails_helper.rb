ENV['RAILS_ENV'] ||= 'test'

require 'simplecov'
SimpleCov.start 'rails'

require 'spec_helper'
require File.expand_path('../../config/environment', __FILE__)
require 'rspec/rails'
ActiveRecord::Migration.maintain_test_schema!

RSpec.configure do |config|

  config.use_transactional_fixtures = false
end

class ApiHelper
  def self.authenticated_request path, params = {}
    [path, params.merge(access_key: "EDx19D72bH7e5I64EXk1kwa4jXvynddS")]
  end

end
