require "rails_helper"

describe AttendeeService do

  describe '.set_usage_names!' do
    let(:locale)          { 'fr' }
    let(:is_formal)       { false }
    let(:attendees)       { [Attendee.new(email: 'bobby@juliedesk.com', first_name: 'Bobby', last_name: 'Doe', gender: 'm')] }


    #subject! {  }

    context 'when formal' do
      let(:is_formal) { true }
      before(:example) do
        expect_any_instance_of(AttendeeService)
          .to receive(:get_usage_name).with({locale: 'fr', formal: true,  first_name: 'Bobby', last_name: 'Doe', gender: 'm' })
          .and_return('Monsieur Doe')
      end

      it 'sets usage name' do
        AttendeeService.set_usage_names!(attendees, { locale: locale, is_formal: is_formal })
        expect(attendees).to include(an_object_having_attributes(usage_name: 'Monsieur Doe'))
      end
    end

    context 'when not formal' do
      let(:is_formal) { false }
      before(:example) do
        expect_any_instance_of(AttendeeService)
            .to receive(:get_usage_name).with({locale: 'fr', formal: false,  first_name: 'Bobby', last_name: 'Doe', gender: 'm' })
                    .and_return('Bobby Doe')
      end

      it 'sets usage name' do
        AttendeeService.set_usage_names!(attendees, { locale: locale, is_formal: is_formal })
        expect(attendees).to include(an_object_having_attributes(usage_name: 'Bobby Doe'))
      end
    end
  end


  describe '.clean_and_categorize_clients!' do
    let(:attendees)  do
      [Attendee.new(email: 'bob@juliedesk.com')]
    end

    context 'when attendee is a client' do
        let(:accounts) { [ { 'email' => 'bob@juliedesk.com', 'usage_name' => 'Bob', 'first_name' => 'Robert', 'last_name' => 'Doe', 'email_aliases' => [] } ] }
        before(:example) { expect(Account).to receive(:get_active_account_emails).with(detailed: true).and_return(accounts) }

        it 'sets account attributes on attendee' do
          AttendeeService.clean_and_categorize_clients!(attendees)
          expect(attendees).to include(an_object_having_attributes(account_email: 'bob@juliedesk.com', email: 'bob@juliedesk.com', first_name: 'Robert', last_name: 'Doe', usage_name: 'Bob'))
        end
    end

    context 'when attendee email is a client alias' do
      let(:accounts) { [ { 'email' => 'bob@gmail.com', 'usage_name' => 'Bob', 'first_name' => 'Robert', 'last_name' => 'Doe', 'email_aliases' => ['bob@juliedesk.com'] } ] }
      before(:example) { expect(Account).to receive(:get_active_account_emails).with(detailed: true).and_return(accounts) }

      it 'sets account attributes on attendee' do
        AttendeeService.clean_and_categorize_clients!(attendees)
        expect(attendees).to include(an_object_having_attributes(account_email: 'bob@gmail.com', email: 'bob@juliedesk.com', first_name: 'Robert', last_name: 'Doe', usage_name: 'Bob'))
      end
    end

    context 'when attendee is not a client' do
      it 'does leave attendee in its state' do
        expect_any_instance_of(AttendeeService).not_to receive(:clean_and_categorize!)
        AttendeeService.clean_and_categorize_clients!(attendees)
      end
    end

  end
end