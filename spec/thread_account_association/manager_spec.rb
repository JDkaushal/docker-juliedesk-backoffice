require "rails_helper"

describe ThreadAccountAssociation::Manager do

  describe 'compute_association_v2' do
    let(:julie) { create(:julie_alias, { email: 'julie@juliedesk.com'}) }
    let(:ups_julie) { create(:julie_alias, { email: 'julie@ups.com'}) }
    let(:julie_aliases) { [ups_julie, julie] }
    let!(:julie_aliases_company_association) do
      REDIS_FOR_ACCOUNTS_CACHE.set('julie_aliases_company_association', { "julie@ups.com"=>"UPS"}.to_json)
    end

    let(:accounts_cache) do
      {
          'bruce.lee@ups.com' => {'email' => 'bruce.lee@ups.com', 'first_name' => 'Bruce', 'last_name' => 'Lee', 'usage_name' => 'M. Lee', 'full_name' => 'Bruce Lee', 'email_aliases' => ['bruce.lee@yopmail.com'], 'company_hash' => {'name' => 'UPS'}, 'configured' => true, 'subscribed' => true },
          'john.wayne@ups.com' => {'email' => 'john.wayne@ups.com', 'first_name' => 'John', 'last_name' => 'Wayne', 'usage_name' => 'John', 'Wayne' => 'John Wayne', 'email_aliases' => ['john.wayne@yopmail.com'], 'company_hash' => {'name' => 'UPS'}, 'configured' => true, 'subscribed' => true },
          'steven.seagul@pepsi.com' => {'email' => 'steven.seagul@pepsi.com', 'first_name' => 'Steven', 'last_name' => 'Seagul', 'usage_name' => 'Steven', 'full_name' => 'Seagul', 'email_aliases' => ['steven.seagul@pepsi.com'], 'company_hash' => {'name' => 'Pepsi'}, 'configured' => true, 'subscribed' => true },
          'bud.spencer@pepsi.com' => {'email' => 'bud.spencer@pepsi.com', 'first_name' => 'Bud', 'last_name' => 'Spencer', 'usage_name' => 'Bud', 'full_name' => 'Spencer', 'email_aliases' => ['bud.spencer@pepsi.com'], 'company_hash' => {'name' => 'Pepsi'}, 'configured' => true, 'subscribed' => true },
          'man.first@nocompany.com' => {'email' => 'man.first@nocompany.com', 'first_name' => 'Man', 'last_name' => 'First', 'usage_name' => 'Man', 'full_name' => 'First', 'email_aliases' => ['man.first@google.com'], 'configured' => true, 'subscribed' => true },
          'manno.second@nocompany.com' => {'email' => 'man.second@nocompany.com', 'first_name' => 'Manno', 'last_name' => 'Second', 'usage_name' => 'Manno', 'full_name' => 'Second', 'email_aliases' => ['man.second@google.com'], 'configured' => true, 'subscribed' => true },
          'clach.third@nocompany.com' => {'email' => 'clach.third@nocompany.com', 'first_name' => 'Clach', 'last_name' => 'Third', 'usage_name' => 'Clach', 'full_name' => 'Third', 'email_aliases' => ['clach.third@google.com'], 'configured' => true, 'subscribed' => true },
          'machin.bidule@nocompany.com' => {'email' => 'machin.bidule@nocompany.com', 'first_name' => 'Machin', 'last_name' => 'Bidule', 'usage_name' => 'Machin', 'full_name' => 'Bidule', 'email_aliases' => ['machin.bidule@google.com'], 'configured' => false, 'subscribed' => true },
          'klark.kent@nocompany.com' => {'email' => 'klark.kent@nocompany.com', 'first_name' => 'Klark', 'last_name' => 'Kent', 'usage_name' => 'Klark', 'full_name' => 'Kent', 'email_aliases' => ['klark.kent@google.com'], 'configured' => false, 'subscribed' => true },
      }
    end

    let!(:set_redis_cache) do
      accounts_cache.each do |email, account_hash|
        REDIS_FOR_ACCOUNTS_CACHE.set(email, account_hash.to_json)
      end
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

    context 'Association to main client' do
      context 'when there are clients in from, to or cc fields' do
        before(:example) do
          manager.compute_association_v2
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

        context 'when client email alias is present in `cc` field' do
          let(:server_message_attributes) { { 'cc' => "Bruce lee <bruce.lee@yopmail.com>" } }
          it { expect(messages_thread.account_email).to eq('bruce.lee@ups.com') }
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
    end

    context 'Primary list building' do
      before(:example) do
        messages_thread.account_email = 'bruce.lee@ups.com'
        manager.compute_association_v2
      end

      let(:data_holder) { ThreadAccountAssociation::DataHolder.new(accounts_cache, julie_aliases, [ups_julie.email]) }

      context 'Clients are in recipients' do
        let(:server_message_attributes) { { 'from' => "Bruce lee <bruce.lee@ups.com>", 'to' => "Machin Bidule <machin.bidule@nocompany.com>, Bud Spencer <bud.spencer@pepsi.com>, Man First <man.first@nocompany.com>, Steven Seagul <steven.seagul@pepsi.com>, Clach Third <clach.third@nocompany.com>, John Wayne <john.WAYNE@ups.com>, Julie Desk <julie@ups.com>", 'cc' => "Manno Second <manno.second@nocompany.com>, Klark Kent <klark.kent@nocompany.com>" } }
        it 'should compute the right primary list and order it properly' do
          expect(messages_thread.accounts_candidates_primary_list).to eq(["bruce.lee@ups.com", "john.wayne@ups.com", "bud.spencer@pepsi.com", "man.first@nocompany.com", "steven.seagul@pepsi.com", "clach.third@nocompany.com", "machin.bidule@nocompany.com", "klark.kent@nocompany.com"])
        end
      end

      context 'client alias in recipients' do
        let(:server_message_attributes) { { 'from' => "Bruce lee <bruce.lee@ups.com>", 'to' => "Machin Bidule <machin.bidule@nocompany.com>, Bud Spencer <bud.spencer@pepsi.com>, Man First <man.first@nocompany.com>, Steven Seagul <steven.seagul@pepsi.com>, Clach Third <clach.third@nocompany.com>, John Wayne <john.wayne@yopmail.com>, Julie Desk <julie@ups.com>", 'cc' => "Manno Second <manno.second@nocompany.com>, Klark Kent <klark.kent@nocompany.com>" } }
        it 'should compute the right primary list and order it properly' do
          expect(messages_thread.accounts_candidates_primary_list).to eq(["bruce.lee@ups.com", "john.wayne@ups.com", "bud.spencer@pepsi.com", "man.first@nocompany.com", "steven.seagul@pepsi.com", "clach.third@nocompany.com", "machin.bidule@nocompany.com", "klark.kent@nocompany.com"])
        end
      end
    end

    context 'secondary list building' do
      before(:example) do
        messages_thread.account_email = 'bruce.lee@ups.com'
        manager.compute_association_v2
      end

      let(:data_holder) { ThreadAccountAssociation::DataHolder.new(accounts_cache, julie_aliases, [ups_julie.email]) }

      context 'Clients are in the body of an email and have a julie alias that is recipient in the current thread, they have their first name or last name in one of the email' do
        let(:server_message_attributes) { { 'from' => "Bruce lee <bruce.lee@ups.com>", 'to' => "Machin Bidule <machin.bidule@nocompany.com>, Bud Spencer <bud.spencer@pepsi.com>, Man First <man.first@nocompany.com>, Steven Seagul <steven.seagul@pepsi.com>, Clach Third <clach.third@nocompany.com>, Julie Desk <julie@ups.com>", 'cc' => "Manno Second <manno.second@nocompany.com>, Klark Kent <klark.kent@nocompany.com>" } }

        context 'Last name is in email' do
          let(:server_thread) do
            {
                'messages' => [
                    {
                        'text' => 'Hi Julie ! Please create a event i my calendar with somebody else, like for example Wayne',
                        'from' => "Somebody <somebody@yopmail.com",
                        'to'   => "Somebody else <somebodyelse@yopmailcom>",
                        'cc'   => "Julie <julie@ups.com>, Stranger <stranger@yopmailcom>",
                        'date' => '2017-01-08T13:00:00Z',
                        'from_me' =>false
                    }
                ]
            }
          end

          it 'should build the correct secondary list' do
            expect(messages_thread.accounts_candidates_secondary_list).to eq(['john.wayne@ups.com'])
          end
        end

        context 'last name is in email' do
          let(:server_thread) do
            {
                'messages' => [
                    {
                        'text' => 'Hi Julie ! Please create a event i my calendar with somebody else, like for example Mr Wayne',
                        'from' => "Somebody <somebody@yopmail.com",
                        'to'   => "Somebody else <somebodyelse@yopmailcom>",
                        'cc'   => "Julie <julie@ups.com>, Stranger <stranger@yopmailcom>",
                        'date' => '2017-01-08T13:00:00Z',
                        'from_me' =>false
                    }
                ]
            }
          end

          it 'should build the correct secondary list' do
            expect(messages_thread.accounts_candidates_secondary_list).to eq(['john.wayne@ups.com'])
          end
        end

        context 'first name is in email' do
          let(:server_thread) do
            {
                'messages' => [
                    {
                        'text' => 'Hi Julie ! Please create a event i my calendar with somebody else, like for example John',
                        'from' => "Somebody <somebody@yopmail.com",
                        'to'   => "Somebody else <somebodyelse@yopmailcom>",
                        'cc'   => "Julie <julie@ups.com>, Stranger <stranger@yopmailcom>",
                        'date' => '2017-01-08T13:00:00Z',
                        'from_me' =>false
                    }
                ]
            }
          end

          it 'should not match any client email' do
            expect(messages_thread.accounts_candidates_secondary_list).to eq([])
          end
        end


      end

      context 'Clients are in the ICS of one of the messages' do
        let(:server_message_attributes) {
          {
              'id' => 1,
              'from' => "Bruce lee <bruce.lee@ups.com>",
              'to' => "Machin Bidule <machin.bidule@nocompany.com>, Bud Spencer <bud.spencer@pepsi.com>, Man First <man.first@nocompany.com>, Steven Seagul <steven.seagul@pepsi.com>",
              'cc' => "Manno Second <manno.second@nocompany.com>, Klark Kent <klark.kent@nocompany.com>",
              'attachments_data' => [
                                      {
                                        'filename' => 'invite.ics',
                                        'name' => 'invite.ics',
                                        'type' => 'application/ics',
                                        'attachment_id' => 'ggtl-frefe-fferf',
                                        'content_id' =>'',
                                        'data_is_blocked' =>false
                                      }
                                    ]
          }
        }

        before(:example) do
          allow_any_instance_of(Message).to receive(:server_message).and_return(server_message)
          expect_any_instance_of(EmailServerInterface).to receive(:build_request).with(:fetch_ics, {:message_id=>1, :attachment_id=>"ggtl-frefe-fferf"}).and_return({'data' => "BEGIN:VCALENDAR\r\nPRODID:-//Google Inc//Google Calendar 70.9054//EN\r\nVERSION:2.0\r\nCALSCALE:GREGORIAN\r\nMETHOD:REQUEST\r\nBEGIN:VEVENT\r\nDTSTART:20170418T140000Z\r\nDTEND:20170418T150000Z\r\nDTSTAMP:20170418T134956Z\r\nORGANIZER:mailto:bruce.lee@ups.comr\nUID:0qf680auedq4vfifbhqe40d9q4@google.com\r\nATTENDEE;CUTYPE=INDIVIDUAL;ROLE=REQ-PARTICIPANT;PARTSTAT=NEEDS-ACTION;RSVP=\r\n TRUE;CN=bruce.lee@ups.com;X-NUM-GUESTS=0:mailto:bruce.lee@ups.com\r\nATTENDEE;CUTYPE=INDIVIDUAL;ROLE=REQ-PARTICIPANT;PARTSTAT=ACCEPTED;RSVP=TRUE\r\n ;X-NUM-GUESTS=0:mailto:clach.third@nocompany.com\r\nCREATED:20170418T134956Z\r\nDESCRIPTION:View your event at https://www.google.com/calendar/event?action\r\n =VIEW&eid=MHFmNjgwYXVlZHE0dmZpZmJocWU0MGQ5cTQgZnJlZGVyaWNAanVsaWVkZXNrLmNvb\r\n Q&tok=MjQjZnJlZGVyaWMuZ3JhaXNAZ21haWwuY29tNGQxNjE3M2M3NGNmOTlmMDRkYThkN2NlY\r\n mY0YjFiOTEzM2IzODU0YQ&ctz=Europe/Paris&hl=en.\r\nLAST-MODIFIED:20170418T134956Z\r\nLOCATION:\r\nSEQUENCE:0\r\nSTATUS:CONFIRMED\r\nSUMMARY:Test invit\r\nTRANSP:OPAQUE\r\nEND:VEVENT\r\nEND:VCALENDAR\r\n"})
          messages_thread.account_email = 'bruce.lee@ups.com'
          manager.compute_association_v2
        end

        it 'should build the correct secondary list' do
          expect(messages_thread.accounts_candidates_secondary_list).to eq(["bruce.lee@ups.com", "clach.third@nocompany.com"])
        end
      end

      context 'Client has its email in the body of one of the emails' do
        let(:server_message_attributes) { { 'from' => "Bruce lee <bruce.lee@ups.com>", 'to' => "Machin Bidule <machin.bidule@nocompany.com>, Bud Spencer <bud.spencer@pepsi.com>, Man First <man.first@nocompany.com>, Steven Seagul <steven.seagul@pepsi.com>, Julie Desk <julie@ups.com>", 'cc' => "Manno Second <manno.second@nocompany.com>, Klark Kent <klark.kent@nocompany.com>" } }

        context 'The client email is its main email' do
          let(:server_thread) do
            {
                'messages' => [
                    {
                        'text' => 'Hi Julie ! Please create a event i my calendar with somebody else, like for example clach.third@nocompany.com',
                        'from' => "Somebody <somebody@yopmail.com",
                        'to'   => "Somebody else <somebodyelse@yopmailcom>",
                        'cc'   => "Julie <julie@ups.com>, Stranger <stranger@yopmailcom>",
                        'date' => '2017-01-08T13:00:00Z',
                        'from_me' =>false
                    }
                ]
            }
          end

          it 'should build the correct secondary list' do
            expect(messages_thread.accounts_candidates_secondary_list).to eq(['clach.third@nocompany.com'])
          end
        end

        context 'The client email is one of its aliases' do
          let(:server_thread) do
            {
                'messages' => [
                    {
                        'text' => 'Hi Julie ! Please create a event i my calendar with somebody else, like for example clach.third@google.com',
                        'from' => "Somebody <somebody@yopmail.com",
                        'to'   => "Somebody else <somebodyelse@yopmailcom>",
                        'cc'   => "Julie <julie@ups.com>, Stranger <stranger@yopmailcom>",
                        'date' => '2017-01-08T13:00:00Z',
                        'from_me' =>false
                    }
                ]
            }
          end

          it 'should build the correct secondary list' do
            expect(messages_thread.accounts_candidates_secondary_list).to eq(['clach.third@nocompany.com'])
          end
        end
      end

      context 'All together' do
        let(:server_message_attributes) {
          {
              'id' => 1,
              'from' => "Bruce lee <bruce.lee@ups.com>",
              'to' => "Machin Bidule <machin.bidule@nocompany.com>, Bud Spencer <bud.spencer@pepsi.com>, Man First <man.first@nocompany.com>, Julie Desk <julie@ups.com>",
              'cc' => "Manno Second <manno.second@nocompany.com>, Klark Kent <klark.kent@nocompany.com>" ,
              'attachments_data' => [
                  {
                      'filename' => 'invite.ics',
                      'name' => 'invite.ics',
                      'type' => 'application/ics',
                      'attachment_id' => 'ggtl-frefe-fferf',
                      'content_id' =>'',
                      'data_is_blocked' =>false
                  }
              ]
          }
        }

        let(:server_thread) do
          {
              'messages' => [
                  {
                      'text' => 'Hi Julie ! Please create a event i my calendar with somebody else, like for example steven.seagul@pepsi.com and Wayne',
                      'from' => "Somebody <somebody@yopmail.com",
                      'to'   => "Somebody else <somebodyelse@yopmailcom>",
                      'cc'   => "Julie <julie@ups.com>, Stranger <stranger@yopmailcom>",
                      'date' => '2017-01-08T13:00:00Z',
                      'from_me' =>false
                  }
              ]
          }
        end

        before(:example) do
          allow_any_instance_of(Message).to receive(:server_message).and_return(server_message)
          expect_any_instance_of(EmailServerInterface).to receive(:build_request).with(:fetch_ics, {:message_id=>1, :attachment_id=>"ggtl-frefe-fferf"}).and_return({'data' => "BEGIN:VCALENDAR\r\nPRODID:-//Google Inc//Google Calendar 70.9054//EN\r\nVERSION:2.0\r\nCALSCALE:GREGORIAN\r\nMETHOD:REQUEST\r\nBEGIN:VEVENT\r\nDTSTART:20170418T140000Z\r\nDTEND:20170418T150000Z\r\nDTSTAMP:20170418T134956Z\r\nORGANIZER:mailto:bruce.lee@ups.comr\nUID:0qf680auedq4vfifbhqe40d9q4@google.com\r\nATTENDEE;CUTYPE=INDIVIDUAL;ROLE=REQ-PARTICIPANT;PARTSTAT=NEEDS-ACTION;RSVP=\r\n TRUE;CN=bruce.lee@ups.com;X-NUM-GUESTS=0:mailto:bruce.lee@ups.com\r\nATTENDEE;CUTYPE=INDIVIDUAL;ROLE=REQ-PARTICIPANT;PARTSTAT=ACCEPTED;RSVP=TRUE\r\n ;X-NUM-GUESTS=0:mailto:clach.third@nocompany.com\r\nCREATED:20170418T134956Z\r\nDESCRIPTION:View your event at https://www.google.com/calendar/event?action\r\n =VIEW&eid=MHFmNjgwYXVlZHE0dmZpZmJocWU0MGQ5cTQgZnJlZGVyaWNAanVsaWVkZXNrLmNvb\r\n Q&tok=MjQjZnJlZGVyaWMuZ3JhaXNAZ21haWwuY29tNGQxNjE3M2M3NGNmOTlmMDRkYThkN2NlY\r\n mY0YjFiOTEzM2IzODU0YQ&ctz=Europe/Paris&hl=en.\r\nLAST-MODIFIED:20170418T134956Z\r\nLOCATION:\r\nSEQUENCE:0\r\nSTATUS:CONFIRMED\r\nSUMMARY:Test invit\r\nTRANSP:OPAQUE\r\nEND:VEVENT\r\nEND:VCALENDAR\r\n"})
          messages_thread.account_email = 'bruce.lee@ups.com'
          manager.compute_association_v2
        end

        it 'should build the correct secondary list' do
          expect(messages_thread.accounts_candidates_secondary_list).to eq(["john.wayne@ups.com", "bruce.lee@ups.com", "clach.third@nocompany.com", "steven.seagul@pepsi.com"])
        end
      end
    end

    context 'Special behavior' do
      let(:data_holder) { ThreadAccountAssociation::DataHolder.new(accounts_cache, julie_aliases, [ups_julie.email]) }

      context 'Thread owner is not configured' do
        let(:accounts_cache) do
          {
              'bruce.lee@ups.com' => {'email' => 'bruce.lee@ups.com', 'first_name' => 'Bruce', 'last_name' => 'Lee', 'usage_name' => 'M. Lee', 'full_name' => 'Bruce Lee', 'email_aliases' => ['bruce.lee@yopmail.com'], 'company_hash' => {'name' => 'UPS'}, 'configured' => false, 'subscribed' => true },
          }
        end
        let(:server_message_attributes) { { 'from' => "Bruce lee <bruce.lee@ups.com>", 'to' => "Machin Bidule <machin.bidule@nocompany.com>, Bud Spencer <bud.spencer@pepsi.com>, Man First <man.first@nocompany.com>, Steven Seagul <steven.seagul@pepsi.com>, Julie Desk <julie@ups.com>", 'cc' => "Manno Second <manno.second@nocompany.com>, Klark Kent <klark.kent@nocompany.com>" } }

        it 'should trigger unconfigured thread owner actions' do
          expect(manager).to receive(:thread_owner_is_not_configured_actions)
          manager.compute_association_v2
        end
      end

      context 'Thread has no owner and we can suggest merging to the operator' do
        let(:accounts_cache) do
          {
            'bruce.lee@ups.com' => {'email' => 'bruce.lee@ups.com', 'first_name' => 'Bruce', 'last_name' => 'Lee', 'usage_name' => 'M. Lee', 'full_name' => 'Bruce Lee', 'email_aliases' => ['bruce.lee@yopmail.com'], 'company_hash' => {'name' => 'UPS'}, 'configured' => false, 'subscribed' => true },
          }
        end

        let(:server_message_attributes) { { 'from' => "Machin Bidule <machin.bidule@nocompany.com>", 'to' => "Bud Spencer <bud.spencer@pepsi.com>, Man First <man.first@nocompany.com>, Steven Seagul <steven.seagul@pepsi.com>, Julie Desk <julie@ups.com>", 'cc' => "Manno Second <manno.second@nocompany.com>, Klark Kent <klark.kent@nocompany.com>" } }

        before(:example) do
          messages_thread.account_email = nil
          messages_thread.computed_recipients = ['machin.bidule@nocompany.com', 'bruce.lee@ups.com', 'bud.spencer@pepsi.com', '<man.first@nocompany.com', 'steven.seagul@pepsi.com', 'manno.second@nocompany.com', 'klark.kent@nocompany.com']
          FactoryGirl.create(:messages_thread, computed_recipients: ['machin.bidule@nocompany.com', 'bruce.lee@ups.com', 'bud.spencer@pepsi.com'], updated_at: Time.now - 1.week)
        end

        it 'should trigger the suggest_merging actions' do
          expect(manager).to receive(:suggest_merging)
          manager.compute_association_v2
        end
      end

      context 'Thread has no owner, cannot suggest merging and can send an automatic message' do
        let(:accounts_cache) do
          {
              'bruce.lee@ups.com' => {'email' => 'bruce.lee@ups.com', 'first_name' => 'Bruce', 'last_name' => 'Lee', 'usage_name' => 'M. Lee', 'full_name' => 'Bruce Lee', 'email_aliases' => ['bruce.lee@yopmail.com'], 'company_hash' => {'name' => 'UPS'}, 'configured' => false, 'subscribed' => true },
          }
        end

        let(:server_message_attributes) {
          {
              'from' => "Machin Bidule <machin.bidule@nocompany.com>",
              'to' => "Bud Spencer <bud.spencer@pepsi.com>, Man First <man.first@nocompany.com>, Steven Seagul <steven.seagul@pepsi.com>, Julie Desk <julie@ups.com>",
              'cc' => "Manno Second <manno.second@nocompany.com>, Klark Kent <klark.kent@nocompany.com>"
          }
        }

        before(:example) do
          messages_thread.account_email = nil
        end

        it 'should trigger the automatic account request email actions' do
          expect(manager).to receive(:send_automatic_email_then_archive)
          manager.compute_association_v2
        end
      end

      context 'when thread is a meeting response' do
        let(:server_message_attributes) do
          { 'from' => 'Bob <bob@nocompany.com>', 'to' => 'Julie Desk <julie@ups.com>', 'cc' => '', 'labels' => ['MEETING_RESPONSE', 'INBOX'] }
        end

        before(:example) { messages_thread.account_email = nil }

        it 'does not trigger automatic reply' do
          expect(manager).not_to receive(:send_automatic_email_then_archive)
          manager.compute_association_v2
        end
      end

    end
  end
end