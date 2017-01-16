require "rails_helper"

describe ThreadAccountAssociation::Manager do

  describe '#compute_association' do
    let(:julie) { create(:julie_alias, { email: 'julie@juliedesk.com'}) }
    let(:ups_julie) { create(:julie_alias, { email: 'julie@ups.com'}) }
    let(:julie_aliases) { [ups_julie, julie] }
    let!(:julie_aliases_company_association) do
      REDIS_FOR_ACCOUNTS_CACHE.set('julie_aliases_company_association', { "julie@ups.com"=>"UPS"}.to_json)
    end

    let(:accounts_cache) do
      {
          'bruce.lee@ups.com' => { "email" => 'bruce.lee@ups.com', "usage_name" => 'M. Lee', "full_name" => 'Bruce Lee', "email_aliases" => ['bruce.lee@yopmail.com'] },
          'john.wayne@ups.com' => {'email' => 'john.wayne@ups.com', 'usage_name' => 'John', 'Wayne' => 'John Wayne', 'email_aliases' => ['john.wayne@yopmail.com'] },
          'steven.seagul@pepsi.com' => {'email' => 'steven.seagul@pepsi.com', 'usage_name' => 'Steven', 'full_name' => 'Seagul', 'email_aliases' => ['steven.seagul@pepsi.com'] },
          'bud.spencer@pepsi.com' => {'email' => 'bud.spencer@pepsi.com', 'usage_name' => 'Bud', 'full_name' => 'Spencer', 'email_aliases' => ['bud.spencer@pepsi.com'] }
      }
    end

    let!(:ups_cache) {
      cache = [
          {"name"=>"Bruce Lee", "firstName"=>"Bruce", "lastName"=>"Lee", "email"=>"bruce.lee@ups.com", "isClient"=>"true", "assisted"=>"false", "assistedBy"=>nil},
          {"name"=>"John Wayne", "firstName"=>"John", "lastName"=>"Wayne", "email"=>"john.wayne@ups.com", "isClient"=>"true", "assisted"=>"false", "assistedBy"=>nil}
      ]
      REDIS_FOR_ACCOUNTS_CACHE.set('UPS', cache.to_json)
    }
    let!(:pepsi_cache) {
      cache = [
          {"name"=>"Steven Seagul", "firstName"=>"Steven", "lastName"=>"Seagul", "email"=>"steven.seagul@pepsi.com", "isClient"=>"true", "assisted"=>"false", "assistedBy"=>nil},
          {"name"=>"Bud Spencer", "firstName"=>"Bud", "lastName"=>"Spencer", "email"=>"bud.spencer@pepsi.com", "isClient"=>"true", "assisted"=>"false", "assistedBy"=>nil}
      ]
      REDIS_FOR_ACCOUNTS_CACHE.set('Pepsi', cache.to_json)
    }

    let(:messages_thread_attributes) { { } }
    let(:messages_thread) { create(:messages_thread_with_messages, {messages_count: 1}.merge!(messages_thread_attributes)) }
    let(:server_thread) do
      {
          'messages' => [
              {
                  'text' => 'Hi Julie ! Please create a event i my calendar with somebody else',
                  'from' => "Somebody <somebody@yopmail.com",
                  'to'   => "Somebody else <somebodyelse@yopmailcom>",
                  'cc'   => "Julie <julie@ups.com>, Stranger <stranger@yopmailcom>",
                  'date' => '2017-01-08T13:00:00Z',
                  'from_me' =>false
              }
          ]
      }
    end
    let(:server_thread_with_multiple_messages) do
      st = server_thread.dup
      st['messages'] << {
          'text' => 'Hi Julie ! I forgot to add his email address',
          'from' => "Somebody <dude@yopmail.com",
          'to'   => "Somebody else <otherdude@yopmailcom>",
          'cc'   => "Julie <julie@ups.com>, Stranger <stranger@yopmailcom>",
          'date' => '2017-01-08T14:00:00Z',
          'from_me' =>false
      }
      st
    end

    let(:server_message_attributes) { { } }
    let!(:server_message) { server_thread['messages'].first.merge!(server_message_attributes) }
    let(:manager_attributes) { { } }
    let(:manager) { ThreadAccountAssociation::Manager.new({data_holder: data_holder, messages_thread: messages_thread, server_thread: server_thread}.merge(manager_attributes)) }

    before(:example) do
      allow(Account).to receive(:accounts_cache).with(mode: 'light').and_return(accounts_cache)
      allow(EmailServer).to receive(:get_messages_thread).and_return(server_thread)
    end

    context 'when there are clients in from, to or cc fields' do
      before(:example) do
        allow(manager).to receive(:send_account_request_email)
        allow_any_instance_of(MessagesThread).to receive(:archive)
        manager.compute_association
      end

      let(:data_holder) { ThreadAccountAssociation::DataHolder.new(accounts_cache, julie_aliases, [ups_julie.email]) }


      context 'when client email is present in `from` field' do
        let(:server_message_attributes) { { 'from' => "Bruce lee <bruce.lee@ups.com>" } }
        it { expect(messages_thread.account_email).to eq('bruce.lee@ups.com') }
      end

      context 'when client email is present in `to` field'  do
        let(:server_message_attributes) { { 'to' => "Bruce lee <bruce.lee@ups.com>" } }
        it { expect(messages_thread.account_email).to eq("bruce.lee@ups.com")}
      end

      context 'when clients email alias is present in `to` field' do
        let(:server_message_attributes) { {'to' => "Bruce Lee <bruce.lee@yopmail.com>" } }
        it { expect(messages_thread.account_email).to eq("bruce.lee@ups.com") }
      end

      context 'when client email is present in `to` field in one of the thread message' do
        let(:manager_attributes) {
          server_thread_with_multiple_messages['messages'].last['to'] = "John Wayne <john.wayne@ups.com>"
          { server_thread: server_thread_with_multiple_messages }
        }

        it "associate thread to client" do
          expect(messages_thread.account_email).to eq("john.wayne@ups.com")
        end
      end

      context 'when clients email alias is present in `to` field of an email sent by Julie' do
        let(:server_message_attributes) { {'from' => 'Julie <julie@ups.com>', 'to' => "Bruce Lee <bruce.lee@yopmail.com>", 'from_me' =>true } }
        it do
          pending 'To reactivate when we will not look in julie emails anymore'
          expect(messages_thread.account_email).to be_nil
        end
      end

      context 'when clients emails are present in `to` and `cc` fields'  do
        let(:server_message_attributes) { {'to' => "Bruce lee <bruce.lee@ups.com>", 'cc' => "John Wayne <john.wayne@ups.com>" } }
        it { expect(messages_thread.account_email).to eq("bruce.lee@ups.com") }
      end

      context 'when clients emails aliases are present in `to` and `cc` fields'  do
        let(:server_message_attributes) { {'to' => "Bruce lee <bruce.lee@yopmail.com>", 'cc' => "John Wayne <john.wayne@yopmail.com>" } }
        it { expect(messages_thread.account_email).to eq("bruce.lee@ups.com") }
      end

      context 'when clients emails are present in `to` field and message body'  do
        let(:server_message_attributes) { { 'to' => "Bruce lee <bruce.lee@ups.com>", "text" => "Hi John Wayne (john.wayne@ups.com)" } }
        it { expect(messages_thread.account_email).to eq('bruce.lee@ups.com') }
      end

      context 'when client email is present in `cc` field' do
        let(:server_message_attributes) { { 'cc' => "Bruce lee <bruce.lee@ups.com>" } }
        it { expect(messages_thread.account_email).to eq('bruce.lee@ups.com') }
      end

      context 'when client email is present in `cc` field of one of the thread messages' do
        let(:manager_attributes) {
          server_thread_with_multiple_messages['messages'].last['to'] = "John Wayne <john.wayne@ups.com>"
          { server_thread: server_thread_with_multiple_messages }
        }

        it "associate thread to client" do
          expect(messages_thread.account_email).to eq("john.wayne@ups.com")
        end
      end

      context 'when client email is present in `cc` field of an email sent by Julie' do
        let(:server_message_attributes) { { 'cc' => "Bruce lee <bruce.lee@ups.com>", 'from_me' => true } }
        it do
          pending 'To reactivate when we will not look in julie emails anymore'
          expect(messages_thread.account_email).to be_nil
        end
      end

      context 'when client email alias is present in `cc` field' do
        let(:server_message_attributes) { { 'cc' => "Bruce lee <bruce.lee@yopmail.com>" } }
        it { expect(messages_thread.account_email).to eq('bruce.lee@ups.com') }
      end

      context 'when client email alias is present in `cc` field of an email sent by Julie' do
        let(:server_message_attributes) { { 'cc' => "Bruce lee <bruce.lee@yopmail.com>", 'from_me' => true } }
        it do
          pending 'To reactivate when we will not look in julie emails anymore'
          expect(messages_thread.account_email).to be_nil
        end
      end

      context 'when client are present in `cc` field and message body' do
        let(:server_message_attributes) { { 'cc' => "Bruce lee <bruce.lee@ups.com>", 'text' => "Hi John Wayne (john.wayne@ups.com)" } }
        it { expect(messages_thread.account_email).to eq('bruce.lee@ups.com') }
      end

      context 'when clients emails are present in `cc` field' do
        let(:server_message_attributes) { { 'cc' => "Bruce lee <bruce.lee@ups.com>, John Wayne <john.wayne@ups.com>" } }
        it { expect(messages_thread.account_email).to eq('bruce.lee@ups.com') }
      end
    end


    context 'when there are no clients in from, to or cc fields' do
      let(:data_holder) { ThreadAccountAssociation::DataHolder.new(accounts_cache, julie_aliases, [ups_julie.email]) }

      context 'and only one client is associated to julie alias' do
        let!(:ups_cache) {
          cache = [{"name"=>"John Wayne", "firstName"=>"John", "lastName"=>"Wayne", "email"=>"john.wayne@ups.com", "isClient"=>"true", "assisted"=>"false", "assistedBy"=>nil}]
          REDIS_FOR_ACCOUNTS_CACHE.set('UPS', cache.to_json)
        }
        let(:server_message_attributes) { { 'cc' => 'Julie <julie@ups.com' } }
        it 'associate thread to this client' do
          manager.compute_association
          expect(messages_thread.account_email).to eq('john.wayne@ups.com')
        end
      end


      context 'and multiple clients are related to julie' do
        let(:server_message_attributes) { { 'cc' =>'Julie <julie@ups.com', 'text' => 'Julie, please organize an event with John Wayne : john.wayne@ups.com'} }

        it 'do not associate thread to anyone' do
          manager.compute_association
          expect(messages_thread.account_email).to be_nil
        end
      end


      context 'and multiple clients related to julie and email is in message body' do
        let(:server_message_attributes) { { 'cc' => 'Julie <julie@ups.com', 'text' => 'Julie, please organize an event with me and this guy : john.wayne@ups.com' } }
        subject! { manager.compute_association }

        it { expect(messages_thread.accounts_candidates).to eql(['john.wayne@ups.com']) }
        it { expect(messages_thread.account_email).to be_nil}
      end

      context 'and multiple clients related to julie and email is in message body sent by julie' do
        let(:server_message_attributes) { { 'from' => 'Julie <julie@ups.com',  'cc' => 'Julie <julie@ups.com', 'text' => 'Julie, please organize an event with me and this guy : john.wayne@ups.com', 'from_me' => true  } }
        subject! {
          allow_any_instance_of(MessagesThread).to receive(:archive)
          manager.compute_association
        }

        it do
          pending 'To reactivate when we will not look in julie emails anymore'
          expect(messages_thread.accounts_candidates).to eql([])
        end

        it { expect(messages_thread.account_email).to be_nil }
      end


      context 'and julie is julie@juliedesk.com and email is in message body' do
        let(:data_holder) { ThreadAccountAssociation::DataHolder.new(accounts_cache, julie_aliases, [julie.email]) }
        let(:server_message_attributes) { { 'cc' => 'Julie <julie@juliedesk.com', 'text' => 'Julie, please organize an event with Bud Spencer : bud.spencer@pepsi.com' } }
        subject! { manager.compute_association }

        it { expect(messages_thread.accounts_candidates).to eql(['bud.spencer@pepsi.com']) }
        it { expect(messages_thread.account_email).to be_nil }
      end

      context 'and julie is julie@juliedesk.com and email is in message body' do
        let(:data_holder) { ThreadAccountAssociation::DataHolder.new(accounts_cache, julie_aliases, [julie.email]) }
        let(:server_message_attributes) { { 'from' => 'Julie <julie@juliedesk.com>', 'cc' => 'Julie <julie@juliedesk.com', 'text' => 'Julie, please organize an event with Bud Spencer : bud.spencer@pepsi.com', 'from_me' => true  } }
        subject! {
          allow_any_instance_of(MessagesThread).to receive(:archive)
          manager.compute_association
        }

        it 'add client as potential thread account' do
          pending 'To reactivate when we will not look in julie emails anymore'
          expect(messages_thread.accounts_candidates).to eql([])
        end

        it { expect(messages_thread.account_email).to be_nil }
      end

      context 'and contact email is present in a less than 3 weeks old thread' do
        let(:data_holder) { ThreadAccountAssociation::DataHolder.new(accounts_cache, julie_aliases, [ups_julie.email]) }
        let(:messages_thread_attributes) { { computed_recipients: ["john@yopmail.com", "billy@ups.com"] } }
        let(:server_message_attributes) { { 'from' => 'john@ups.com',  'to' => 'Billy <billy@ups.com>',  'cc' => 'Julie <julie@ups.com' } }
        before(:example) { create(:messages_thread_with_messages, messages_count: 2, computed_recipients: ['billy@ups.com', 'bob@ups.com']) }
        subject! { manager.compute_association }

        it 'add client as potential merging candidate' do
          expect(messages_thread.accounts_candidates).to eq(["billy@ups.com"])
        end

        it 'set messages thread as to be merged' do
          expect(messages_thread.account_association_merging_possible).to eq(true)
        end

        it 'doe not associate thread to anyone' do
          expect(messages_thread.account_email).to be_nil
        end
      end

      context 'and contact email is present in a more than 3 weeks old thread' do
        let(:data_holder) { ThreadAccountAssociation::DataHolder.new(accounts_cache, julie_aliases, [ups_julie.email]) }
        let(:messages_thread_attributes) { { computed_recipients: ["john@yopmail.com", "billy@ups.com"] } }
        let(:server_message_attributes) { { 'from' => 'john@ups.com',  'to' => 'Billy <billy@ups.com>',  'cc' => 'Julie <julie@ups.com' } }
        before(:example) {
          create(:messages_thread_with_messages, messages_count: 2, computed_recipients: ['billy@ups.com', 'bob@ups.com'], updated_at: 1.month.ago)
          allow(manager).to receive(:send_account_request_email)
          allow_any_instance_of(MessagesThread).to receive(:archive)
        }

        subject! { manager.compute_association }

        it 'add client as potential merging candidate' do
          expect(messages_thread.accounts_candidates.empty?).to eq(true)
        end

        it 'do not set messages thread as to be merged' do
          expect(messages_thread.to_be_merged).to eq(false)
        end

        it 'do not associate thread to anyone' do
          expect(messages_thread.account_email).to be_nil
        end
      end


      context 'and multiple clients related to custom julie and last name is in message body' do
        let(:data_holder) { ThreadAccountAssociation::DataHolder.new(accounts_cache, julie_aliases, [ups_julie.email]) }
        let(:server_message_attributes) { { 'cc' => 'Julie <julie@ups.com', 'text' => 'Julie, please organize an event with Mr Wayne' } }
        before(:example) { manager.compute_association }

        it { expect(messages_thread.accounts_candidates).to eql(['john.wayne@ups.com']) }
        it { expect(messages_thread.account_email).to be_nil }
      end

      context 'and multiple clients related to julie@juliedesk.com and last name is in message body' do
        let(:data_holder) { ThreadAccountAssociation::DataHolder.new(accounts_cache, julie_aliases, [julie.email]) }
        let(:server_message_attributes) { { 'cc' => 'Julie <julie@juliesk.com', 'text' => 'Julie, please organize an event with Mr Wayne' } }
        before(:example) {
          allow(manager).to receive(:send_account_request_email)
          allow_any_instance_of(MessagesThread).to receive(:archive)
          manager.compute_association
        }

        it { expect(messages_thread.accounts_candidates).not_to include("john.wayne@ups.com") }
        it { expect(messages_thread.account_email).to be_nil }
      end



      context 'and multiple clients related to custom julie and first name is in message body' do
        let(:data_holder) { ThreadAccountAssociation::DataHolder.new(accounts_cache, julie_aliases, [ups_julie.email]) }
        let(:server_message_attributes) { { 'cc' => 'Julie <julie@ups.com', 'text' => 'Julie, please organize an event with John' } }
        before(:example) { manager.compute_association }

        it { expect(messages_thread.accounts_candidates).to eql(['john.wayne@ups.com']) }
        it { expect(messages_thread.account_email).to be_nil }
      end


      context 'and multiple clients related to julie@juliedesk.com and first name is in message body' do
        let(:data_holder) { ThreadAccountAssociation::DataHolder.new(accounts_cache, julie_aliases, [julie.email]) }
        let(:server_message_attributes) { { 'cc' => 'Julie <julie@juliesk.com', 'text' => 'Julie, please organize an event with John' }}

        before(:example) {
          allow(manager).to receive(:send_account_request_email)
          allow_any_instance_of(MessagesThread).to receive(:archive)
          manager.compute_association
        }

        it { expect(messages_thread.accounts_candidates).not_to include("john.wayne@ups.com") }
        it { expect(messages_thread.account_email).to be_nil }
      end


      context 'and multiple clients are related to Julie and account candidates are empty' do
        let(:server_message_attributes) { { 'cc' => 'Julie <julie@ups.com' }}
        let(:data_holder) { ThreadAccountAssociation::DataHolder.new(accounts_cache, julie_aliases, [ups_julie.email]) }

        it 'send a reply email to the sender' do
          allow_any_instance_of(MessagesThread).to receive(:archive)
          expect(manager).to receive(:send_account_request_email)
          manager.compute_association
        end

        it 'archive message thread' do
          allow(manager).to receive(:send_account_request_email)
          expect_any_instance_of(MessagesThread).to receive(:archive)
          manager.compute_association
        end

      end


      context 'multiple clients are related to Julie and account request email already send' do
        let(:server_message_attributes) { { 'cc' => 'Julie <julie@ups.com' }}
        let(:messages_thread_attributes) { { account_request_auto_email_sent: true } }
        let(:data_holder) { ThreadAccountAssociation::DataHolder.new(accounts_cache, julie_aliases, [ups_julie.email]) }
        after(:example) { manager.compute_association  }

        it 'do not send reply email to the sender' do
          expect(manager).not_to receive(:send_account_request_email)
        end

        it 'do not archive message thread' do
          expect_any_instance_of(MessagesThread).not_to receive(:archive)
        end
      end

    end

  end

end