require "rails_helper"

describe MessagesThreadFlows::ThreadOwnerIsInactive do
  let(:julie) { create(:julie_alias, { email: 'julie@juliedesk.com'}) }
  let(:ups_julie) { create(:julie_alias, { email: 'julie@ups.com'}) }
  let(:julie_aliases) { [ups_julie, julie] }

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
  let(:data_holder) { ThreadAccountAssociation::DataHolder.new(accounts_cache, julie_aliases, [ups_julie.email]) }
  let(:manager) { ThreadAccountAssociation::Manager.new(data_holder: data_holder, messages_thread: messages_thread, server_thread: server_thread) }
  let(:thread_owner_is_inactive_flow) { MessagesThreadFlows::ThreadOwnerIsInactive.new(manager) }

  let(:accounts_cache) do
    {
        'bruce.lee@ups.com' => {'email' => 'bruce.lee@ups.com', 'first_name' => 'Bruce', 'last_name' => 'Lee', 'usage_name' => 'M. Lee', 'full_name' => 'Bruce Lee', 'email_aliases' => ['bruce.lee@yopmail.com'], 'company_hash' => {'name' => 'UPS'}, 'configured' => true, 'subscribed' => true },
        'john.wayne@ups.com' => {'email' => 'john.wayne@ups.com', 'first_name' => 'John', 'last_name' => 'Wayne', 'usage_name' => 'John', 'Wayne' => 'John Wayne', 'email_aliases' => ['john.wayne@yopmail.com'], 'company_hash' => {'name' => 'UPS'}, 'configured' => true, 'subscribed' => true },
        'steven.seagul@pepsi.com' => {'email' => 'steven.seagul@pepsi.com', 'first_name' => 'Steven', 'last_name' => 'Seagul', 'usage_name' => 'Steven', 'full_name' => 'Seagul', 'email_aliases' => ['steven.seagul@pepsi.com'], 'company_hash' => {'name' => 'Pepsi'}, 'configured' => true, 'subscribed' => true },
        'bud.spencer@pepsi.com' => {'email' => 'bud.spencer@pepsi.com', 'first_name' => 'Bud', 'last_name' => 'Spencer', 'usage_name' => 'Bud', 'full_name' => 'Spencer', 'email_aliases' => ['bud.spencer@pepsi.com'], 'company_hash' => {'name' => 'Pepsi'}, 'configured' => true, 'subscribed' => true },
        'man.first@nocompany.com' => {'email' => 'man.first@nocompany.com', 'first_name' => 'Man', 'last_name' => 'First', 'usage_name' => 'Man', 'full_name' => 'First', 'email_aliases' => ['man.first@google.com'], 'configured' => true, 'subscribed' => true },
        'manno.second@nocompany.com' => {'email' => 'manno.second@nocompany.com', 'first_name' => 'Manno', 'last_name' => 'Second', 'usage_name' => 'Manno', 'full_name' => 'Second', 'email_aliases' => ['manno.second@google.com'], 'configured' => true, 'subscribed' => true },
        'clach.third@nocompany.com' => {'email' => 'clach.third@nocompany.com', 'first_name' => 'Clach', 'last_name' => 'Third', 'usage_name' => 'Clach', 'full_name' => 'Third', 'email_aliases' => ['clach.third@google.com'], 'configured' => true, 'subscribed' => true },
        'machin.bidule@nocompany.com' => {'email' => 'machin.bidule@nocompany.com', 'first_name' => 'Machin', 'last_name' => 'Bidule', 'usage_name' => 'Machin', 'full_name' => 'Bidule', 'email_aliases' => ['machin.bidule@google.com'], 'configured' => false, 'subscribed' => true },
        'klark.kent@nocompany.com' => {'email' => 'klark.kent@nocompany.com', 'first_name' => 'Klark', 'last_name' => 'Kent', 'usage_name' => 'Klark', 'full_name' => 'Kent', 'email_aliases' => ['klark.kent@google.com'], 'configured' => false, 'subscribed' => true },
        'captain.flamme@nocompany.com' => {'email' => 'captain.flamme@nocompany.com', 'first_name' => 'Captain', 'last_name' => 'Flamme', 'usage_name' => 'Captain', 'full_name' => 'Flamme', 'email_aliases' => ['captain.flamme@google.com'], 'configured' => true, 'subscribed' => false },
        'rocket.launcher@nocompany.com' => {'email' => 'rocket.launcher@nocompany.com', 'first_name' => 'Rocket', 'last_name' => 'Launcher', 'usage_name' => 'Rocket', 'full_name' => 'Launcher', 'email_aliases' => ['rocket.launcher@google.com'], 'configured' => true, 'subscribed' => false },
    }
  end
  let!(:set_redis_cache) do
    accounts_cache.each do |email, account_hash|
      REDIS_FOR_ACCOUNTS_CACHE.set(email, account_hash.to_json)
    end
  end

  describe 'flow' do

    context 'Will enter the flow' do
      let(:messages_thread_attributes) { {account_email: 'captain.flamme@nocompany.com'} }

      it 'should call the trigger method' do
        expect(thread_owner_is_inactive_flow).to receive(:enter)
        thread_owner_is_inactive_flow.trigger
      end

      context 'The messages thread accounts candidates primary list is not empty' do
        context 'The first client in the primary list is still subscribed to the service' do
          let(:messages_thread_attributes) { {account_email: 'captain.flamme@nocompany.com', accounts_candidates_primary_list: ['manno.second@nocompany.com']} }

          it 'should reassociate the messages thread to this client' do
            thread_owner_is_inactive_flow.trigger
            expect(messages_thread.account_email).to eq('manno.second@nocompany.com')
          end
        end

        context 'The first client in the primary list is no longer subscribed to the service' do
          let(:messages_thread_attributes) { {account_email: 'captain.flamme@nocompany.com', accounts_candidates_primary_list: ['rocket.launcher@nocompany.com', 'manno.second@nocompany.com']} }

          it 'should reassociate the messages thread to the next client' do
            thread_owner_is_inactive_flow.trigger
            expect(messages_thread.account_email).to eq('manno.second@nocompany.com')
          end
        end
      end

      context 'The messages thread accounts candidates primary list is empty' do
        let(:messages_thread_attributes) { {account_email: 'captain.flamme@nocompany.com', accounts_candidates_primary_list: []} }

        before(:example) do
          manager.send(:compute_recipients_emails_for_last_message)
        end

        context 'The old client is present in the last message recipients' do
          let(:server_thread) do
            {
              'messages' => [
                {
                  'text' => 'Hi Julie ! Please create a event i my calendar with somebody else',
                  'from' => "Somebody <somebody@yopmail.com",
                  'to'   => "Captain Flamme <captain.flamme@nocompany.com>",
                  'cc'   => "Julie <julie@ups.com>, Stranger <stranger@yopmailcom>",
                  'date' => '2017-01-08T13:00:00Z',
                  'from_me' =>false
                }
              ]
            }
          end

          it 'should send the right automatic email' do
            expect(thread_owner_is_inactive_flow).to receive(:send_notice_email_to_old_client).with(Message.last, 'captain.flamme@nocompany.com')
            expect(messages_thread).to receive(:archive)
            thread_owner_is_inactive_flow.trigger
          end
        end

        context 'The old client is not present in the last message recipients' do
          let(:server_thread) do
            {
                'messages' => [
                    {
                        'text' => 'Hi Julie ! Please create a event i my calendar with somebody else',
                        'from' => "Somebody <somebody@yopmail.com",
                        'to'   => "Not client <not.client@nocompany.com>",
                        'cc'   => "Julie <julie@ups.com>, Stranger <stranger@yopmailcom>",
                        'date' => '2017-01-08T13:00:00Z',
                        'from_me' =>false
                    }
                ]
            }
          end

          it 'should send the right automatic email' do
            expect(thread_owner_is_inactive_flow).to receive(:send_notice_email_to_interlocutor).with(Message.last, 'captain.flamme@nocompany.com')
            expect(messages_thread).to receive(:archive)
            thread_owner_is_inactive_flow.trigger
          end
        end
      end
    end

    # context 'Will not enter the flow' do
    #   let(:messages_thread_attributes) { {account_email: 'bruce.lee@ups.com'} }
    #
    #   it 'should not call the trigger method' do
    #     expect(thread_owner_is_inactive_flow).not_to receive(:enter)
    #     thread_owner_is_inactive_flow.trigger
    #   end
    # end
  end
end



