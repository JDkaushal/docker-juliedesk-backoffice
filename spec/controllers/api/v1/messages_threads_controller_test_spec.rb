require_relative "../../../rails_helper"

describe Api::V1::MessagesThreadsController, :type => :controller do

  describe 'Inheritance' do
    it { expect(described_class).to be < Api::ApiV1Controller }
  end



  describe 'messages_thread_context' do
    before do
      request.headers['Authorization'] = ENV['API_KEY']

      @mt1 = FactoryGirl.create(:messages_thread_with_messages, server_thread_id: 666)
    end

    xit 'should return the correct context for the messages_thread' do
      pending 'Waiting for reactivation'
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
                                                      "sent_to_admin" => @mt1.sent_to_admin,
                                                      "has_been_sent_to_admin" => @mt1.has_been_sent_to_admin,
                                                      "to_admin_message" => @mt1.to_admin_message,
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
                                                      "handled_by_ai"=>false,
                                                      "request_date"=>nil,
                                                      "messages_count"=>0,
                                                      "handled_by_automation"=>false,
                                                      "is_multi_clients"=>false,
                                                      "computed_recipients"=>[],
                                                      "accounts_candidates"=>[],
                                                      "account_request_auto_email_sent"=>false,
                                                      "account_association_merging_possible" => false,
                                                      "linked_attendees"=>{},
                                                      "clients_in_recipients"=>[],
                                                      "allowed_attendees"=>[],
                                                      "accounts_candidates_primary_list"=>[],
                                                      "accounts_candidates_secondary_list"=>[],
                                                      "merging_account_candidates"=>[]
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
                                                        "allowed_attendees"=>[]
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
                                                              "location_changed" => nil,
                                                              "virtual_resource_used" => nil,
                                                              "before_update_data"=>nil,
                                                              "verified_dates_by_ai" => nil,
                                                              "annotated_reply"=>nil,
                                                              "language_level"=>nil,
                                                              "asap_constraint"=>false
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
                                                            "event_from_invitation_organizer"=>nil,
                                                            "date_suggestions_full_ai"=>false
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