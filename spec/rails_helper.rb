ENV['RAILS_ENV'] ||= 'test'

require 'simplecov'
SimpleCov.start 'rails'

require 'spec_helper'
require File.expand_path('../../config/environment', __FILE__)
require 'rspec/rails'
require 'webmock/rspec'
ActiveRecord::Migration.maintain_test_schema!

RSpec.configure do |config|
  config.use_transactional_fixtures = false


  config.expect_with :rspec do |expectations|
    expectations.include_chain_clauses_in_custom_matcher_descriptions = true
  end

  config.mock_with :rspec do |mocks|
    mocks.verify_partial_doubles = true
  end

  config.include FactoryGirl::Syntax::Methods



  config.before(:each) do
    DatabaseCleaner.strategy = :deletion
  end

  config.after(:each) do
    DatabaseCleaner.clean
    REDIS_FOR_ACCOUNTS_CACHE.flushall
  end

  config.after(:each, use_archive_db: true) do
    current_conf = ActiveRecord::Base.connection_config
    ActiveRecord::Base.establish_connection Rails.configuration.database_configuration["archive_test"]
    DatabaseCleaner.clean
    ActiveRecord::Base.establish_connection current_conf
    DatabaseCleaner.clean
  end
end