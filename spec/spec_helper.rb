require 'factory_girl'

require_relative "../spec/factories/client_contacts.rb"
require_relative "../spec/factories/event_title_review.rb"
require_relative "../spec/factories/messages_threads.rb"
require_relative "../spec/factories/messages.rb"
require_relative "../spec/factories/message_classifications.rb"
require_relative "../spec/factories/message_interpretations.rb"
require_relative "../spec/factories/julie_actions.rb"
require_relative "../spec/factories/operators.rb"
require_relative "../spec/factories/operator_presence.rb"
require_relative "../spec/factories/operator_actions.rb"
require_relative "../spec/factories/operator_actions_groups.rb"
require_relative "../spec/factories/julie_aliases.rb"

RSpec.configure do |config|
  config.expect_with :rspec do |expectations|
    expectations.include_chain_clauses_in_custom_matcher_descriptions = true
  end

  config.mock_with :rspec do |mocks|
    mocks.verify_partial_doubles = true
  end

  config.include FactoryGirl::Syntax::Methods

  config.before(:suite) do
    DatabaseCleaner.clean_with(:truncation)
  end

  config.before(:each) do
    DatabaseCleaner.strategy = :transaction
  end

  config.before(:each, :js => true) do
    DatabaseCleaner.strategy = :truncation
  end

  config.before(:each) do
    DatabaseCleaner.start
    REDIS_FOR_ACCOUNTS_CACHE.flushall
  end

  config.after(:each) do
    DatabaseCleaner.clean
    REDIS_FOR_ACCOUNTS_CACHE.flushall
  end
end
