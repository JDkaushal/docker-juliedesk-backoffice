#include RSpec::Matchers

module MockingHelpers
  class Attendees
    RSpec::Mocks::Syntax.enable_expect(self)
    RSpec::Expectations::Syntax.enable_expect(self)
    def initialize
    end

    def mock(attendees)
      add_clients_to_cache(attendees.select{|att| att['isClient'] == 'true'})

      attendees.each{|att| mock_attendee(att)}
      mock_messages_thread_contacts(attendees)
    end

    private

    def mock_messages_thread_contacts(attendees)
      expect(MessagesThread).to receive(:contacts).and_return(attendees)
    end

    def mock_attendee(att)
      expect(AI_PROXY_INTERFACE).to receive(:build_request).with(:parse_human_civilities, {:fullname=>att['name'], :at=>att['email']}).and_return('first_name' => att['firstName'], 'last_name' => att['lastName'], 'gender' => att['gender'])
      expect(AI_PROXY_INTERFACE).to receive(:build_request).with(:get_company_name, {:address=>att['email'], :message=>""}).and_return('company' => att['company'])

      expect_any_instance_of(AutomaticProcessing::AutomatedMessageClassification).to receive(:get_usage_name).with({:locale=>"en", :first_name=>att['firstName'], :last_name=>att['lastName'], :gender=>att['gender'], :formal=>false}).and_return("Monsieur #{att['name']}")
    end

    def add_clients_to_cache(atts)
      allow(REDIS_FOR_ACCOUNTS_CACHE).to receive(:get).and_call_original
      allow(REDIS_FOR_ACCOUNTS_CACHE).to receive(:get).with('clients_emails').and_return(atts.map{ |att| att['email'] }.to_json)
    end
  end
end