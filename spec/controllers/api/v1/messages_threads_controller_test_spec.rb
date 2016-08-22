require_relative "../../../rails_helper"

describe Api::V1::MessagesThreadsController, :type => :controller do

  describe 'Inheritance' do
    it { expect(described_class).to be < Api::ApiV1Controller }
  end

  describe 'inbox_count' do
    before do
      request.headers['Authorization'] = "EDx19D72bH7e5I64EXk1kwa4jXvynddS"
    end
    it 'should return 0 messages threads count when no threads in inbox' do
      mt1 = FactoryGirl.create(:messages_thread_for_inbox_count)
      mt2 = FactoryGirl.create(:messages_thread_for_inbox_count)
      mt3 = FactoryGirl.create(:messages_thread_for_inbox_count)
      mt4 = FactoryGirl.create(:messages_thread_for_inbox_count)
      mt5 = FactoryGirl.create(:messages_thread_for_inbox_count)

      get :inbox_count

      expect(response.body).to eq("{\"status\":\"success\",\"data\":{\"count\":0,\"admin_count\":0,\"global_productivity\":0,\"individual_productivity\":null,\"priority_count\":0,\"follow_up_messages_threads_priority\":0,\"follow_up_messages_threads_main\":0}}")
    end

    it 'should return the messages threads for admin count when there are threads in inbox that are not delegated to founders and no accounts are retrieved from the redis accounts cache ' do
      mt1 = FactoryGirl.create(:messages_thread_for_inbox_count_in_inbox)
      mt2 = FactoryGirl.create(:messages_thread_for_inbox_count_in_inbox)
      mt3 = FactoryGirl.create(:messages_thread_for_inbox_count_in_inbox)
      mt4 = FactoryGirl.create(:messages_thread_for_inbox_count_in_inbox)
      mt5 = FactoryGirl.create(:messages_thread_for_inbox_count_in_inbox)

      get :inbox_count

      expect(response.body).to eq("{\"status\":\"success\",\"data\":{\"count\":0,\"admin_count\":5,\"global_productivity\":0,\"individual_productivity\":null,\"priority_count\":0,\"follow_up_messages_threads_priority\":0,\"follow_up_messages_threads_main\":0}}")
    end

    it 'should return the messages threads for admin count when there are threads in inbox that are delegated to founders' do
      mt1 = FactoryGirl.create(:messages_thread_for_inbox_count_delegated_to_founders_in_inbox)
      mt2 = FactoryGirl.create(:messages_thread_for_inbox_count_delegated_to_founders_in_inbox)
      mt3 = FactoryGirl.create(:messages_thread_for_inbox_count_delegated_to_founders_in_inbox)
      mt4 = FactoryGirl.create(:messages_thread_for_inbox_count_delegated_to_founders_in_inbox)
      mt5 = FactoryGirl.create(:messages_thread_for_inbox_count_delegated_to_founders_in_inbox)

      get :inbox_count

      expect(response.body).to eq("{\"status\":\"success\",\"data\":{\"count\":0,\"admin_count\":5,\"global_productivity\":0,\"individual_productivity\":null,\"priority_count\":0,\"follow_up_messages_threads_priority\":0,\"follow_up_messages_threads_main\":0}}")
    end

    it 'should return the messages threads for admin count when there are threads in inbox that have an account set to only_admin_can_process or that have no accounts founds in the cache' do
      mt1 = FactoryGirl.create(:messages_thread_for_inbox_count_in_inbox)
      mt2 = FactoryGirl.create(:messages_thread_for_inbox_count_in_inbox)
      mt3 = FactoryGirl.create(:messages_thread_for_inbox_count_in_inbox)
      mt4 = FactoryGirl.create(:messages_thread_for_inbox_count_in_inbox)
      mt5 = FactoryGirl.create(:messages_thread_for_inbox_count_in_inbox)

      allow(Account).to receive(:accounts_cache).and_return({mt1.account_email => {"only_admin_can_process" => true}, mt2.account_email => {"only_admin_can_process" => true}, mt3.account_email => {"only_admin_can_process" => true}})

      get :inbox_count

      expect(response.body).to eq("{\"status\":\"success\",\"data\":{\"count\":0,\"admin_count\":5,\"global_productivity\":0,\"individual_productivity\":null,\"priority_count\":0,\"follow_up_messages_threads_priority\":0,\"follow_up_messages_threads_main\":0}}")
    end

    it 'should return the correct messages threads count when there are threads in inbox that have an account found in the cache' do
      mt1 = FactoryGirl.create(:messages_thread_for_inbox_count_in_inbox)
      mt2 = FactoryGirl.create(:messages_thread_for_inbox_count_in_inbox)
      mt3 = FactoryGirl.create(:messages_thread_for_inbox_count_in_inbox)
      mt4 = FactoryGirl.create(:messages_thread_for_inbox_count_in_inbox)
      mt5 = FactoryGirl.create(:messages_thread_for_inbox_count_in_inbox)

      allow(Account).to receive(:accounts_cache).and_return({mt1.account_email => {"only_admin_can_process" => false, 'full_name' => 'f n'}, mt2.account_email => {"only_admin_can_process" => false, 'full_name' => 'f n'}, mt3.account_email => {"only_admin_can_process" => false, 'full_name' => 'f n'}, mt4.account_email => {"only_admin_can_process" => false, 'full_name' => 'f n'}, mt5.account_email => {"only_admin_can_process" => false, 'full_name' => 'f n'}})

      get :inbox_count

      expect(response.body).to eq("{\"status\":\"success\",\"data\":{\"count\":5,\"admin_count\":0,\"global_productivity\":0,\"individual_productivity\":null,\"priority_count\":0,\"follow_up_messages_threads_priority\":0,\"follow_up_messages_threads_main\":0}}")
    end

    it 'should return the correct messages threads count when there are threads in inbox that have an account found in the cache but some have companies working hours out of bounds' do
      mt1 = FactoryGirl.create(:messages_thread_for_inbox_count_in_inbox)
      mt2 = FactoryGirl.create(:messages_thread_for_inbox_count_in_inbox)
      mt3 = FactoryGirl.create(:messages_thread_for_inbox_count_in_inbox)
      mt4 = FactoryGirl.create(:messages_thread_for_inbox_count_in_inbox)
      mt5 = FactoryGirl.create(:messages_thread_for_inbox_count_in_inbox)

      allow(DateTime).to receive(:now).and_return(DateTime.new(2015, 11, 25, 12, 00, 00))

      allow(Account).to receive(:accounts_cache).and_return({mt1.account_email => {"only_admin_can_process" => false, 'full_name' => 'f n', 'company_hash' => {'timezone' => 'UTC', 'working_hours' => {'wed' => {0 => ['0', '1100']}}}}, mt2.account_email => {"only_admin_can_process" => false, 'full_name' => 'f n', 'company_hash' => {'timezone' => 'UTC', 'working_hours' => {'wed' => {0 => ['1300', '2400']}}}}, mt3.account_email => {"only_admin_can_process" => false, 'full_name' => 'f n', 'company_hash' => {'timezone' => 'UTC', 'working_hours' => {'wed' => {0 => ['800', '1800']}}}}, mt4.account_email => {"only_admin_can_process" => false, 'full_name' => 'f n'}, mt5.account_email => {"only_admin_can_process" => false, 'full_name' => 'f n'}})

      get :inbox_count

      expect(response.body).to eq("{\"status\":\"success\",\"data\":{\"count\":3,\"admin_count\":0,\"global_productivity\":0,\"individual_productivity\":null,\"priority_count\":0,\"follow_up_messages_threads_priority\":0,\"follow_up_messages_threads_main\":0}}")
    end
  end

  describe 'messages_thread_context' do
    before do
      request.headers['Authorization'] = "EDx19D72bH7e5I64EXk1kwa4jXvynddS"

      @mt1 = FactoryGirl.create(:messages_thread_with_messages, server_thread_id: 666)
    end

    it 'should return the correct context for the messages_thread' do
      get :messages_thread_context, id: 666

      expect(JSON.parse(response.body)).to eq({
                                                  "thread" => {
                                                      "id" => @mt1.id,
                                                      "account_email" => @mt1.account_email,
                                                      "in_inbox" => @mt1.in_inbox,
                                                      "locale" => @mt1.locale,
                                                      "created_at" => @mt1.created_at.strftime('%Y-%m-%dT%H:%M:%S.%3NZ'),
                                                      "updated_at" => @mt1.updated_at.strftime('%Y-%m-%dT%H:%M:%S.%3NZ'),
                                                      "subject" => @mt1.subject,
                                                      "snippet" => @mt1.snippet,
                                                      "account_name" => @mt1.account_name,
                                                      "delegated_to_founders" => @mt1.delegated_to_founders,
                                                      "to_founders_message" => @mt1.to_founders_message,
                                                      "locked_by_operator_id" => @mt1.locked_by_operator_id,
                                                      "locked_at" => @mt1.locked_at,
                                                      "server_thread_id" => @mt1.server_thread_id,
                                                      "server_version" => @mt1.server_version,
                                                      "delegated_to_support" => @mt1.delegated_to_support,
                                                      "should_follow_up" => @mt1.should_follow_up,
                                                      "follow_up_instruction" => @mt1.follow_up_instruction,
                                                      "last_operator_id" => nil,
                                                      "event_booked_date" => nil,
                                                      "status" => nil,
                                                      "to_be_merged"=>false,
                                                      "to_be_merged_operator_id"=>nil,
                                                      "was_merged"=>false,
                                                      "follow_up_reminder_date"=>nil,
                                                      "last_relevant_classification_id"=>nil,
                                                      "current_scheduling_status"=>nil,
                                                      "in_scheduling_process"=>nil,
                                                      "event_creation_ja_id"=>nil,
                                                      "last_classification_id"=>nil,
                                                      "last_classification_with_data_id"=>nil,
                                                      "suggested_date_times_ja"=>nil,
                                                      "suggested_date_times_mc"=>nil,
                                                      "next_suggested_status"=>nil,
                                                      "last_message_from_me"=>nil,
                                                      "last_message_sent_at"=>nil
                                                  },
                                                  "messages" => @mt1.messages.map { |m|
                                                    {
                                                        "id" => m.id,
                                                        "messages_thread_id" => m.messages_thread_id,
                                                        "received_at" => nil,
                                                        "created_at" => m.created_at.strftime('%Y-%m-%dT%H:%M:%S.%3NZ'),
                                                        "updated_at" => m.updated_at.strftime('%Y-%m-%dT%H:%M:%S.%3NZ'),
                                                        "archived" => m.archived,
                                                        "reply_all_recipients" => m.reply_all_recipients,
                                                        "from_me" => m.from_me,
                                                        "server_message_id" => m.server_message_id,
                                                        "request_at" => nil,
                                                        "last_relevant_classification_id"=>nil
                                                    }
                                                  },
                                                  "messages_classifications" => @mt1.messages.map { |m|
                                                    {
                                                        m.id.to_s => m.message_classifications.map { |mc|
                                                          {
                                                              "id" => mc.id,
                                                              "classification" => mc.classification,
                                                              "message_id" => mc.message_id,
                                                              "operator" => mc.operator,
                                                              "validated" => mc.validated,
                                                              "appointment_nature" => mc.appointment_nature,
                                                              "summary" => mc.summary,
                                                              "duration" => mc.duration,
                                                              "location" => mc.location,
                                                              "location_coordinates"=>[],
                                                              "attendees" => mc.attendees,
                                                              "notes" => mc.notes,
                                                              "constraints" => mc.constraints,
                                                              "date_times" => mc.date_times,
                                                              "created_at" => mc.created_at.strftime('%Y-%m-%dT%H:%M:%S.%3NZ'),
                                                              "updated_at" => mc.updated_at.strftime('%Y-%m-%dT%H:%M:%S.%3NZ'),
                                                              "locale" => mc.locale,
                                                              "timezone" => mc.timezone,
                                                              "processed_in" => mc.processed_in,
                                                              "location_nature" => mc.location_nature,
                                                              "private" => mc.private,
                                                              "other_notes" => mc.other_notes,
                                                              "constraints_data" => mc.constraints_data,
                                                              "client_agreement" => mc.client_agreement,
                                                              "attendees_are_noticed" => mc.attendees_are_noticed,
                                                              "number_to_call" => mc.number_to_call,
                                                              "review_status" => mc.review_status,
                                                              "call_instructions" => mc.call_instructions,
                                                              "thread_status" => mc.thread_status,
                                                              "follow_up_data" => mc.follow_up_data,
                                                              "title_preference"=>nil,
                                                              "using_meeting_room"=>false,
                                                              "meeting_room_details"=>nil,
                                                              "using_restaurant_booking" => false,
                                                              "restaurant_booking_details" => nil,
                                                              "location_changed" => nil
                                                          }
                                                        }
                                                    }
                                                  },
                                                  "julie_actions" => @mt1.messages.map { |m| m.message_classifications.map { |mc|
                                                    {
                                                        mc.id.to_s => {
                                                            "id" => mc.julie_action.id,
                                                            "message_classification_id" => mc.julie_action.message_classification_id,
                                                            "action_nature" => mc.julie_action.action_nature,
                                                            "date_times" => mc.julie_action.date_times,
                                                            "text" => mc.julie_action.text,
                                                            "generated_text" => mc.julie_action.generated_text,
                                                            "done" => mc.julie_action.done,
                                                            "pending" => mc.julie_action.pending,
                                                            "created_at" => mc.julie_action.created_at.strftime('%Y-%m-%dT%H:%M:%S.%3NZ'),
                                                            "updated_at" => mc.julie_action.updated_at.strftime('%Y-%m-%dT%H:%M:%S.%3NZ'),
                                                            "processed_in" => mc.julie_action.processed_in,
                                                            "calendar_id" => mc.julie_action.calendar_id,
                                                            "event_id" => mc.julie_action.event_id,
                                                            "events" => mc.julie_action.events,
                                                            "deleted_event" => mc.julie_action.deleted_event,
                                                            "event_url" => mc.julie_action.event_url,
                                                            "calendar_login_username" => mc.julie_action.calendar_login_username,
                                                            "server_message_id" => mc.julie_action.server_message_id,
                                                            "event_from_invitation"=>false,
                                                            "event_from_invitation_organizer"=>nil
                                                        }
                                                    }
                                                  }
                                                  }.flatten,
                                                  "current_event" => {
                                                      "event_id" => nil,
                                                      "calendar_id" => nil,
                                                      "event_url" => nil,
                                                      "appointment_nature" => nil,
                                                      "calendar_login_username" => nil,
                                                      "event_from_invitation"=>false,
                                                      "event_from_invitation_organizer"=>nil
                                                  }
                                              })
    end
  end
end