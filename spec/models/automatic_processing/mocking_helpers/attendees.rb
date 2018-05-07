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
      allow_any_instance_of(AttendeeService).to receive(:get_usage_name).with({:locale=>"en", :formal=>false, :first_name=>att['firstName'], :last_name=>att['lastName'], :gender=>att['gender']}).and_return("Monsieur #{att['firstName']} #{att['lastName']}")

      expect(AI_PROXY_INTERFACE).to receive(:build_request).with(:parse_human_civilities, {:fullname=>att['name'], :at=>att['email']}).and_return('first_name' => att['firstName'], 'last_name' => att['lastName'], 'gender' => att['gender'])
      expect(AI_PROXY_INTERFACE).to receive(:build_request).with(:get_company_name, {:address=>att['email'], :message=>""}).and_return('company' => att['company'])
    end

    def add_clients_to_cache(atts)
      allow(Account).to receive(:get_active_account_emails).and_return(atts.map { |att| account_cache_params(att) })
      allow(REDIS_FOR_ACCOUNTS_CACHE).to receive(:get).and_call_original
      allow(REDIS_FOR_ACCOUNTS_CACHE).to receive(:get).with('clients_emails').and_return(atts.map{ |att| att['email'] }.to_json)
    end

    private



    def account_cache_params(attendee)
      {
          'email'                 => attendee['email'],
          'first_name'            => attendee['firstName'],
          'last_name'             => attendee['lastName'],
          'usage_name'            => attendee['usageName'],
          'full_name'             => "#{attendee['firstName']} #{attendee['lastName']}",
          'email_aliases'         => [attendee['email']],
          'company_hash'          => {},
          'default_timezone_id'   => attendee['timezone'],
          'mobile_number'         => attendee['mobile'],
          'landline_number'       => attendee['landline'],
          'confcall_instructions' => attendee['confCallInstructions'],
          'skype'                 => attendee['skypeId'],
          'gender'                => attendee['gender']
      }

    end

  end
end