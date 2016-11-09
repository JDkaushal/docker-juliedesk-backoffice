require "rails_helper"

describe WeeklyRecapHelper do

  describe "get_weekly_recap_data" do
    describe "scheduled" do
      before do
        @scheduled_correct_mt = FactoryGirl.create(:messages_thread, {
                                                                       account_email: "nicolas@juliedesk.com",
                                                                       subject: "Subject correct mt",
                                                                       server_thread_id: 1,
                                                                       messages: [
                                                                           FactoryGirl.create(:message, {
                                                                                                          received_at: "2016-01-10",
                                                                                                          message_classifications: [
                                                                                                              FactoryGirl.create(:message_classification, {
                                                                                                                                                            classification: MessageClassification::ASK_DATE_SUGGESTIONS,
                                                                                                                                                            created_at: "2016-01-10",
                                                                                                                                                            thread_status: MessageClassification::THREAD_STATUS_SCHEDULING_WAITING_FOR_CLIENT,
                                                                                                                                                            julie_action: FactoryGirl.create(:julie_action, {
                                                                                                                                                                                                              done: true
                                                                                                                                                                                                          })
                                                                                                                                                        })
                                                                                                          ]
                                                                                                      }),
                                                                           FactoryGirl.create(:message, {
                                                                                                          received_at: "2016-02-03",
                                                                                                          message_classifications: [
                                                                                                              FactoryGirl.create(:message_classification, {
                                                                                                                                                            classification: MessageClassification::ASK_AVAILABILITIES,
                                                                                                                                                            created_at: "2016-02-03",
                                                                                                                                                            summary: "Skype scheduled on 2016-02-03",
                                                                                                                                                            appointment_nature: "Skype",
                                                                                                                                                            thread_status: MessageClassification::THREAD_STATUS_SCHEDULED,
                                                                                                                                                            attendees: [
                                                                                                                                                                {
                                                                                                                                                                    'email' => "nmarlier@gmail.com",
                                                                                                                                                                    'isPresent' => 'true',
                                                                                                                                                                    'firstName' => "Nico",
                                                                                                                                                                    'lastName' => "M",
                                                                                                                                                                    'company' => "JD"
                                                                                                                                                                }
                                                                                                                                                            ].to_json,
                                                                                                                                                            julie_action: FactoryGirl.create(:julie_action, {
                                                                                                                                                                                                              done: true,
                                                                                                                                                                                                              event_id: "event_id_1",
                                                                                                                                                                                                              calendar_id: "calendar_id_1",
                                                                                                                                                                                                              event_url: "event_url_1",
                                                                                                                                                                                                              calendar_login_username: "calendar_login_username_1",
                                                                                                                                                                                                          })
                                                                                                                                                        })
                                                                                                          ]
                                                                                                      })
                                                                       ]
                                                                   })

        scheduled_before_mt = FactoryGirl.create(:messages_thread, {
                                                                      account_email: "nicolas@juliedesk.com",
                                                                      subject: "Subject before mt",
                                                                      server_thread_id: 1,
                                                                      messages: [
                                                                          FactoryGirl.create(:message, {
                                                                                                         received_at: "2016-01-10",
                                                                                                         message_classifications: [
                                                                                                             FactoryGirl.create(:message_classification, {
                                                                                                                                                           classification: MessageClassification::ASK_DATE_SUGGESTIONS,
                                                                                                                                                           created_at: "2016-01-10",
                                                                                                                                                           thread_status: MessageClassification::THREAD_STATUS_SCHEDULING_WAITING_FOR_CLIENT,
                                                                                                                                                           julie_action: FactoryGirl.create(:julie_action, {
                                                                                                                                                                                                             done: true
                                                                                                                                                                                                         })
                                                                                                                                                       })
                                                                                                         ]
                                                                                                     }),
                                                                          FactoryGirl.create(:message, {
                                                                                                         received_at: "2016-01-31",
                                                                                                         message_classifications: [
                                                                                                             FactoryGirl.create(:message_classification, {
                                                                                                                                                           classification: MessageClassification::ASK_AVAILABILITIES,
                                                                                                                                                           created_at: "2016-01-31",
                                                                                                                                                           summary: "Skype scheduled on 2016-01-31",
                                                                                                                                                           appointment_nature: "Skype",
                                                                                                                                                           thread_status: MessageClassification::THREAD_STATUS_SCHEDULED,
                                                                                                                                                           attendees: [
                                                                                                                                                               {
                                                                                                                                                                   'email' => "nmarlier@gmail.com",
                                                                                                                                                                   'isPresent' => 'true',
                                                                                                                                                                   'firstName' => "Nico",
                                                                                                                                                                   'lastName' => "M",
                                                                                                                                                                   'company' => "JD"
                                                                                                                                                               }
                                                                                                                                                           ].to_json,
                                                                                                                                                           julie_action: FactoryGirl.create(:julie_action, {
                                                                                                                                                                                                             done: true,
                                                                                                                                                                                                             event_id: "event_id_1",
                                                                                                                                                                                                             calendar_id: "calendar_id_1",
                                                                                                                                                                                                             event_url: "event_url_1",
                                                                                                                                                                                                             calendar_login_username: "calendar_login_username_1",
                                                                                                                                                                                                         })
                                                                                                                                                       })
                                                                                                         ]
                                                                                                     })
                                                                      ]
                                                                  })

        scheduled_other_account_email = FactoryGirl.create(:messages_thread, {
                                                                      account_email: "nicolas2@juliedesk.com",
                                                                      subject: "Subject other account mt",
                                                                      server_thread_id: 1,
                                                                      messages: [
                                                                          FactoryGirl.create(:message, {
                                                                                                         received_at: "2016-01-10",
                                                                                                         message_classifications: [
                                                                                                             FactoryGirl.create(:message_classification, {
                                                                                                                                                           classification: MessageClassification::ASK_DATE_SUGGESTIONS,
                                                                                                                                                           created_at: "2016-01-10",
                                                                                                                                                           thread_status: MessageClassification::THREAD_STATUS_SCHEDULING_WAITING_FOR_CLIENT,
                                                                                                                                                           julie_action: FactoryGirl.create(:julie_action, {
                                                                                                                                                                                                             done: true
                                                                                                                                                                                                         })
                                                                                                                                                       })
                                                                                                         ]
                                                                                                     }),
                                                                          FactoryGirl.create(:message, {
                                                                                                         received_at: "2016-02-03",
                                                                                                         message_classifications: [
                                                                                                             FactoryGirl.create(:message_classification, {
                                                                                                                                                           classification: MessageClassification::ASK_AVAILABILITIES,
                                                                                                                                                           created_at: "2016-02-03",
                                                                                                                                                           summary: "Skype scheduled on 2016-02-03 with nicolas2",
                                                                                                                                                           appointment_nature: "Skype",
                                                                                                                                                           thread_status: MessageClassification::THREAD_STATUS_SCHEDULED,
                                                                                                                                                           attendees: [
                                                                                                                                                               {
                                                                                                                                                                   'email' => "nmarlier@gmail.com",
                                                                                                                                                                   'isPresent' => 'true',
                                                                                                                                                                   'firstName' => "Nico",
                                                                                                                                                                   'lastName' => "M",
                                                                                                                                                                   'company' => "JD"
                                                                                                                                                               }
                                                                                                                                                           ].to_json,
                                                                                                                                                           julie_action: FactoryGirl.create(:julie_action, {
                                                                                                                                                                                                             done: true,
                                                                                                                                                                                                             event_id: "event_id_1",
                                                                                                                                                                                                             calendar_id: "calendar_id_1",
                                                                                                                                                                                                             event_url: "event_url_1",
                                                                                                                                                                                                             calendar_login_username: "calendar_login_username_1",
                                                                                                                                                                                                         })
                                                                                                                                                       })
                                                                                                         ]
                                                                                                     })
                                                                      ]
                                                                  })

        scheduled_already_scheduled_account_email = FactoryGirl.create(:messages_thread, {
                                                                               account_email: "nicolas@juliedesk.com",
                                                                               subject: "Subject already scheduled mt",
                                                                               server_thread_id: 1,
                                                                               messages: [
                                                                                   FactoryGirl.create(:message, {
                                                                                                                  received_at: "2016-01-10",
                                                                                                                  message_classifications: [
                                                                                                                      FactoryGirl.create(:message_classification, {
                                                                                                                                                                    classification: MessageClassification::ASK_DATE_SUGGESTIONS,
                                                                                                                                                                    created_at: "2016-01-10",
                                                                                                                                                                    thread_status: MessageClassification::THREAD_STATUS_SCHEDULED,
                                                                                                                                                                    julie_action: FactoryGirl.create(:julie_action, {
                                                                                                                                                                                                                      done: true
                                                                                                                                                                                                                  })
                                                                                                                                                                })
                                                                                                                  ]
                                                                                                              }),
                                                                                   FactoryGirl.create(:message, {
                                                                                                                  received_at: "2016-02-03",
                                                                                                                  message_classifications: [
                                                                                                                      FactoryGirl.create(:message_classification, {
                                                                                                                                                                    classification: MessageClassification::ASK_AVAILABILITIES,
                                                                                                                                                                    created_at: "2016-02-03",
                                                                                                                                                                    summary: "Skype scheduled on 2016-02-03 with nicolas2",
                                                                                                                                                                    appointment_nature: "Skype",
                                                                                                                                                                    thread_status: MessageClassification::THREAD_STATUS_SCHEDULED,
                                                                                                                                                                    attendees: [
                                                                                                                                                                        {
                                                                                                                                                                            'email' => "nmarlier@gmail.com",
                                                                                                                                                                            'isPresent' => 'true',
                                                                                                                                                                            'firstName' => "Nico",
                                                                                                                                                                            'lastName' => "M",
                                                                                                                                                                            'company' => "JD"
                                                                                                                                                                        }
                                                                                                                                                                    ].to_json,
                                                                                                                                                                    julie_action: FactoryGirl.create(:julie_action, {
                                                                                                                                                                                                                      done: true,
                                                                                                                                                                                                                      event_id: "event_id_1",
                                                                                                                                                                                                                      calendar_id: "calendar_id_1",
                                                                                                                                                                                                                      event_url: "event_url_1",
                                                                                                                                                                                                                      calendar_login_username: "calendar_login_username_1",
                                                                                                                                                                                                                  })
                                                                                                                                                                })
                                                                                                                  ]
                                                                                                              })
                                                                               ]
                                                                           })
      end
      it "should behave correctly" do
        data = WeeklyRecapHelper.get_weekly_recap_data({
                                                           account_email: "nicolas@juliedesk.com",
                                                           start_of_week: DateTime.parse("2016-02-01")
                                                       })

        expect(data).to eq([
                               {
                                   :account_email=>"nicolas@juliedesk.com",
                                   :status => "scheduled",
                                   :subject => "Skype scheduled on 2016-02-03",
                                   :thread_subject => "Subject correct mt",
                                   :other =>
                                       {
                                           :id => @scheduled_correct_mt.id,
                                           :server_thread_id => 1,
                                           :event =>
                                               {
                                                   :event_id => "event_id_1",
                                                   :event_url => "event_url_1",
                                                   :calendar_id => "calendar_id_1",
                                                   :appointment_nature => "Skype",
                                                   :calendar_login_username => "calendar_login_username_1",
                                                   :event_from_invitation => false,
                                                   :event_from_invitation_organizer => nil
                                               },
                                           :attendees => [{:email=>"nmarlier@gmail.com", :name=>"Nico M", :company=>"JD"}],
                                           :last_message_received_at => "2016-02-03 00:00:00 UTC"
                                       }
                               }
                           ])
      end
    end

    describe "scheduled not main account" do
      before do
        @scheduled_correct_mt = FactoryGirl.create(:messages_thread, {
                                                                       account_email: "nicolas2@juliedesk.com",
                                                                       subject: "Subject correct mt",
                                                                       server_thread_id: 1,
                                                                       messages: [
                                                                           FactoryGirl.create(:message, {
                                                                                                          received_at: "2016-01-10",
                                                                                                          message_classifications: [
                                                                                                              FactoryGirl.create(:message_classification, {
                                                                                                                                                            classification: MessageClassification::ASK_DATE_SUGGESTIONS,
                                                                                                                                                            created_at: "2016-01-10",
                                                                                                                                                            thread_status: MessageClassification::THREAD_STATUS_SCHEDULING_WAITING_FOR_CLIENT,
                                                                                                                                                            julie_action: FactoryGirl.create(:julie_action, {
                                                                                                                                                                                                              done: true
                                                                                                                                                                                                          })
                                                                                                                                                        })
                                                                                                          ]
                                                                                                      }),
                                                                           FactoryGirl.create(:message, {
                                                                                                          received_at: "2016-02-03",
                                                                                                          message_classifications: [
                                                                                                              FactoryGirl.create(:message_classification, {
                                                                                                                                                            classification: MessageClassification::ASK_AVAILABILITIES,
                                                                                                                                                            created_at: "2016-02-03",
                                                                                                                                                            summary: "Skype scheduled on 2016-02-03",
                                                                                                                                                            appointment_nature: "Skype",
                                                                                                                                                            thread_status: MessageClassification::THREAD_STATUS_SCHEDULED,
                                                                                                                                                            attendees: [
                                                                                                                                                                {
                                                                                                                                                                    'email' => "nmarlier@gmail.com",
                                                                                                                                                                    'account_email' => "nicolas@juliedesk.com",
                                                                                                                                                                    'isPresent' => 'true',
                                                                                                                                                                    'firstName' => "Nico",
                                                                                                                                                                    'lastName' => "M",
                                                                                                                                                                    'company' => "JD"
                                                                                                                                                                }
                                                                                                                                                            ].to_json,
                                                                                                                                                            julie_action: FactoryGirl.create(:julie_action, {
                                                                                                                                                                                                              done: true,
                                                                                                                                                                                                              event_id: "event_id_1",
                                                                                                                                                                                                              calendar_id: "calendar_id_1",
                                                                                                                                                                                                              event_url: "event_url_1",
                                                                                                                                                                                                              calendar_login_username: "calendar_login_username_1",
                                                                                                                                                                                                          })
                                                                                                                                                        })
                                                                                                          ]
                                                                                                      })
                                                                       ]
                                                                   })

        scheduled_incorrect_mt = FactoryGirl.create(:messages_thread, {
                                                                       account_email: "nicolas2@juliedesk.com",
                                                                       subject: "Subject incorrect mt",
                                                                       server_thread_id: 1,
                                                                       messages: [
                                                                           FactoryGirl.create(:message, {
                                                                                                          received_at: "2016-01-10",
                                                                                                          message_classifications: [
                                                                                                              FactoryGirl.create(:message_classification, {
                                                                                                                                                            classification: MessageClassification::ASK_DATE_SUGGESTIONS,
                                                                                                                                                            created_at: "2016-01-10",
                                                                                                                                                            thread_status: MessageClassification::THREAD_STATUS_SCHEDULING_WAITING_FOR_CLIENT,
                                                                                                                                                            julie_action: FactoryGirl.create(:julie_action, {
                                                                                                                                                                                                              done: true
                                                                                                                                                                                                          })
                                                                                                                                                        })
                                                                                                          ]
                                                                                                      }),
                                                                           FactoryGirl.create(:message, {
                                                                                                          received_at: "2016-02-03",
                                                                                                          message_classifications: [
                                                                                                              FactoryGirl.create(:message_classification, {
                                                                                                                                                            classification: MessageClassification::ASK_AVAILABILITIES,
                                                                                                                                                            created_at: "2016-02-03",
                                                                                                                                                            summary: "Skype scheduled on 2016-02-03 bis",
                                                                                                                                                            appointment_nature: "Skype",
                                                                                                                                                            thread_status: MessageClassification::THREAD_STATUS_SCHEDULED,
                                                                                                                                                            attendees: [
                                                                                                                                                                {
                                                                                                                                                                    'email' => "nmarlier@gmail.com",
                                                                                                                                                                    'account_email' => "nicolas2@juliedesk.com",
                                                                                                                                                                    'isPresent' => 'true',
                                                                                                                                                                    'firstName' => "Nico",
                                                                                                                                                                    'lastName' => "M",
                                                                                                                                                                    'company' => "JD"
                                                                                                                                                                }
                                                                                                                                                            ].to_json,
                                                                                                                                                            julie_action: FactoryGirl.create(:julie_action, {
                                                                                                                                                                                                              done: true,
                                                                                                                                                                                                              event_id: "event_id_1",
                                                                                                                                                                                                              calendar_id: "calendar_id_1",
                                                                                                                                                                                                              event_url: "event_url_1",
                                                                                                                                                                                                              calendar_login_username: "calendar_login_username_1",
                                                                                                                                                                                                          })
                                                                                                                                                        })
                                                                                                          ]
                                                                                                      })
                                                                       ]
                                                                   })

      end
      it "should behave correctly" do
        data = WeeklyRecapHelper.get_weekly_recap_data({
                                                           account_email: "nicolas@juliedesk.com",
                                                           start_of_week: DateTime.parse("2016-02-01")
                                                       })

        expect(data).to eq([
                               {
                                   :account_email=>"nicolas@juliedesk.com",
                                   :status => "scheduled",
                                   :subject => "Skype scheduled on 2016-02-03",
                                   :thread_subject => "Subject correct mt",
                                   :other =>
                                       {
                                           :id => @scheduled_correct_mt.id,
                                           :server_thread_id => 1,
                                           :event =>
                                               {
                                                   :event_id => "event_id_1",
                                                   :event_url => "event_url_1",
                                                   :calendar_id => "calendar_id_1",
                                                   :appointment_nature => "Skype",
                                                   :calendar_login_username => "calendar_login_username_1",
                                                   :event_from_invitation => false,
                                                   :event_from_invitation_organizer => nil
                                               },
                                           :attendees => [],
                                           :last_message_received_at => "2016-02-03 00:00:00 UTC"
                                       }
                               }
                           ])
      end
    end

    describe "events_creation" do
      before do
        @events_creation_mt = FactoryGirl.create(:messages_thread, {
                                                                      account_email: "nicolas@juliedesk.com",
                                                                      subject: "Subject creation mt",
                                                                      server_thread_id: 1,
                                                                      messages: [
                                                                          FactoryGirl.create(:message, {
                                                                                                         received_at: "2016-02-03",
                                                                                                         message_classifications: [
                                                                                                             FactoryGirl.create(:message_classification, {
                                                                                                                                                           classification: MessageClassification::ASK_CREATE_EVENT,
                                                                                                                                                           created_at: "2016-02-03",
                                                                                                                                                           summary: "Skype scheduled on 2016-02-03",
                                                                                                                                                           thread_status: MessageClassification::THREAD_STATUS_EVENTS_CREATION,
                                                                                                                                                           julie_action: FactoryGirl.create(:julie_action, {
                                                                                                                                                                                                             action_nature: JulieAction::JD_ACTION_CREATE_EVENT,
                                                                                                                                                                                                             done: true,
                                                                                                                                                                                                             events: [
                                                                                                                                                                                                                 {
                                                                                                                                                                                                                     event_id: "event_id_1",
                                                                                                                                                                                                                     calendar_id: "calendar_id_1",
                                                                                                                                                                                                                     event_url: "event_url_1",
                                                                                                                                                                                                                     calendar_login_username: "calendar_login_username_1",
                                                                                                                                                                                                                 }
                                                                                                                                                                                                             ].to_json
                                                                                                                                                                                                         })
                                                                                                                                                       })
                                                                                                         ]
                                                                                                     })
                                                                      ]
                                                                  })

      end
      it "should behave correctly" do
        data = WeeklyRecapHelper.get_weekly_recap_data({
                                                           account_email: "nicolas@juliedesk.com",
                                                           start_of_week: DateTime.parse("2016-02-01")
                                                       })

        expect(data).to eq([
                               {
                                   :account_email=>"nicolas@juliedesk.com",
                                   :status => "scheduled",
                                   :thread_subject => "Subject creation mt",
                                   :other =>
                                       {
                                           :id => @events_creation_mt.id,
                                           :server_thread_id => 1,
                                           :event =>
                                               {
                                                   :event_id => "event_id_1",

                                                   :calendar_id => "calendar_id_1",
                                                   :event_url => "event_url_1",
                                                   :calendar_login_username => "calendar_login_username_1",
                                                   :messages_thread_id => @events_creation_mt.id,
                                                   :messages_thread_subject => "Subject creation mt",
                                                   :server_thread_id => 1,
                                               },
                                           :attendees => []
                                       }
                               }
                           ])
      end
    end

    describe "scheduling_events waiting for client" do
      before do
        @correct_scheduling_mt = FactoryGirl.create(:messages_thread, {
                                                                        account_email: "nicolas@juliedesk.com",
                                                                        subject: "Subject scheduling mt",
                                                                        server_thread_id: 1,
                                                                        follow_up_reminder_date: DateTime.parse("2016-02-10 00:00:00 UTC"),
                                                                        messages: [
                                                                            FactoryGirl.create(:message, {
                                                                                                           received_at: "2016-02-03",
                                                                                                           message_classifications: [
                                                                                                               FactoryGirl.create(:message_classification, {
                                                                                                                                                             classification: MessageClassification::ASK_DATE_SUGGESTIONS,
                                                                                                                                                             created_at: "2016-02-03",
                                                                                                                                                             summary: "Skype scheduled on 2016-02-03",
                                                                                                                                                             thread_status: MessageClassification::THREAD_STATUS_SCHEDULING_WAITING_FOR_CLIENT,
                                                                                                                                                             appointment_nature: "skype",
                                                                                                                                                             attendees: [
                                                                                                                                                                 {
                                                                                                                                                                     'email' => "nmarlier@gmail.com",
                                                                                                                                                                     'isPresent' => 'true',
                                                                                                                                                                     'firstName' => "Nico",
                                                                                                                                                                     'lastName' => "M",
                                                                                                                                                                     'company' => "JD"
                                                                                                                                                                 }
                                                                                                                                                             ].to_json,
                                                                                                                                                             julie_action: FactoryGirl.create(:julie_action, {
                                                                                                                                                                                                               action_nature: JulieAction::JD_ACTION_CREATE_EVENT,
                                                                                                                                                                                                               done: true,
                                                                                                                                                                                                               events: [
                                                                                                                                                                                                                   {
                                                                                                                                                                                                                       event_id: "event_id_1",
                                                                                                                                                                                                                       calendar_id: "calendar_id_1",
                                                                                                                                                                                                                       event_url: "event_url_1",
                                                                                                                                                                                                                       calendar_login_username: "calendar_login_username_1",
                                                                                                                                                                                                                   }
                                                                                                                                                                                                               ].to_json
                                                                                                                                                                                                           })
                                                                                                                                                         })
                                                                                                           ]
                                                                                                       })
                                                                        ]
                                                                    })

      end
      it "should behave correctly" do
        data = WeeklyRecapHelper.get_weekly_recap_data({
                                                           account_email: "nicolas@juliedesk.com",
                                                           start_of_week: DateTime.parse("2016-02-01")
                                                       })

        expect(data).to eq([
                               {
                                   :account_email=>"nicolas@juliedesk.com",
                                   :status => "scheduling",
                                   :subject => "Skype scheduled on 2016-02-03",
                                   :thread_subject => "Subject scheduling mt",
                                   :other =>
                                       {
                                           :id => @correct_scheduling_mt.id,
                                           :server_thread_id => 1,
                                           :waiting_for => "client",
                                           :valid_suggestions_count => 0,
                                           :suggestions_count => 0,
                                           :appointment_nature => "skype",
                                           :attendees => [{email: "nmarlier@gmail.com", name: "Nico M", company: "JD"}],
                                           :last_message_received_at => "2016-02-03 00:00:00 UTC",
                                           :follow_up_reminder_date => "2016-02-10 00:00:00 UTC"
                                       }
                               }
                           ])
      end
    end

    describe "scheduling_events waiting for contact" do
      before do
        @correct_scheduling_mt = FactoryGirl.create(:messages_thread, {
                                                                        account_email: "nicolas@juliedesk.com",
                                                                        subject: "Subject correct scheduling mt",
                                                                        server_thread_id: 1,
                                                                        messages: [
                                                                            FactoryGirl.create(:message, {
                                                                                                           received_at: "2016-02-03",
                                                                                                           message_classifications: [
                                                                                                               FactoryGirl.create(:message_classification, {
                                                                                                                                                             classification: MessageClassification::ASK_DATE_SUGGESTIONS,
                                                                                                                                                             created_at: "2016-02-03",
                                                                                                                                                             summary: "Skype scheduled on 2016-02-03",
                                                                                                                                                             thread_status: MessageClassification::THREAD_STATUS_SCHEDULING_WAITING_FOR_CONTACT,
                                                                                                                                                             appointment_nature: "skype",
                                                                                                                                                             attendees: [
                                                                                                                                                                 {
                                                                                                                                                                     'email' => "nmarlier@gmail.com",
                                                                                                                                                                     'isPresent' => 'true',
                                                                                                                                                                     'firstName' => "Nico",
                                                                                                                                                                     'lastName' => "M",
                                                                                                                                                                     'company' => "JD"
                                                                                                                                                                 }
                                                                                                                                                             ].to_json,
                                                                                                                                                             julie_action: FactoryGirl.create(:julie_action, {
                                                                                                                                                                                                               action_nature: JulieAction::JD_ACTION_CREATE_EVENT,
                                                                                                                                                                                                               done: true,
                                                                                                                                                                                                               events: [
                                                                                                                                                                                                                   {
                                                                                                                                                                                                                       event_id: "event_id_1",
                                                                                                                                                                                                                       calendar_id: "calendar_id_1",
                                                                                                                                                                                                                       event_url: "event_url_1",
                                                                                                                                                                                                                       calendar_login_username: "calendar_login_username_1",
                                                                                                                                                                                                                   }
                                                                                                                                                                                                               ].to_json
                                                                                                                                                                                                           })
                                                                                                                                                         })
                                                                                                           ]
                                                                                                       })
                                                                        ]
                                                                    })

      end
      it "should behave correctly" do
        data = WeeklyRecapHelper.get_weekly_recap_data({
                                                           account_email: "nicolas@juliedesk.com",
                                                           start_of_week: DateTime.parse("2016-02-01")
                                                       })

        expect(data).to eq([
                               {
                                   :account_email=>"nicolas@juliedesk.com",
                                   :status => "scheduling",
                                   :subject => "Skype scheduled on 2016-02-03",
                                   :thread_subject => "Subject correct scheduling mt",
                                   :other =>
                                       {
                                           :id => @correct_scheduling_mt.id,
                                           :server_thread_id => 1,
                                           :waiting_for => "contact",
                                           :valid_suggestions_count => 0,
                                           :suggestions_count => 0,
                                           :appointment_nature => "skype",
                                           :attendees => [{email: "nmarlier@gmail.com", name: "Nico M", company: "JD"}],
                                           :last_message_received_at => "2016-02-03 00:00:00 UTC",
                                           :follow_up_reminder_date => nil

                                       }
                               }
                           ])
      end
    end


    describe "scheduling aborted" do
      before do
        @correct_scheduling_mt = FactoryGirl.create(:messages_thread, {
                                                                        account_email: "nicolas@juliedesk.com",
                                                                        subject: "Subject scheduling mt",
                                                                        server_thread_id: 1,
                                                                        messages: [
                                                                            FactoryGirl.create(:message, {
                                                                                                           received_at: "2016-02-03",
                                                                                                           message_classifications: [
                                                                                                               FactoryGirl.create(:message_classification, {
                                                                                                                                                             classification: MessageClassification::ASK_DATE_SUGGESTIONS,
                                                                                                                                                             created_at: "2016-02-03",
                                                                                                                                                             summary: "Skype scheduled on 2016-02-03",
                                                                                                                                                             thread_status: MessageClassification::THREAD_STATUS_SCHEDULING_WAITING_FOR_CONTACT,
                                                                                                                                                             appointment_nature: "skype",
                                                                                                                                                             attendees: [
                                                                                                                                                                 {
                                                                                                                                                                     'email' => "nmarlier@gmail.com",
                                                                                                                                                                     'isPresent' => 'true',
                                                                                                                                                                     'firstName' => "Nico",
                                                                                                                                                                     'lastName' => "M",
                                                                                                                                                                     'company' => "JD"
                                                                                                                                                                 }
                                                                                                                                                             ].to_json,
                                                                                                                                                             julie_action: FactoryGirl.create(:julie_action, {
                                                                                                                                                                                                               action_nature: JulieAction::JD_ACTION_CREATE_EVENT,
                                                                                                                                                                                                               done: true,
                                                                                                                                                                                                               events: [
                                                                                                                                                                                                                   {
                                                                                                                                                                                                                       event_id: "event_id_1",
                                                                                                                                                                                                                       calendar_id: "calendar_id_1",
                                                                                                                                                                                                                       event_url: "event_url_1",
                                                                                                                                                                                                                       calendar_login_username: "calendar_login_username_1",
                                                                                                                                                                                                                   }
                                                                                                                                                                                                               ].to_json
                                                                                                                                                                                                           })
                                                                                                                                                         })
                                                                                                           ]
                                                                                                       })
                                                                        ]
                                                                    })

        @correct_scheduling_aborted_mt1 = FactoryGirl.create(:messages_thread, {
                                                                        account_email: "nicolas@juliedesk.com",
                                                                        subject: "Subject scheduling aborted mt",
                                                                        server_thread_id: 1,
                                                                        messages: [
                                                                            FactoryGirl.create(:message, {
                                                                                                           received_at: "2016-01-20",
                                                                                                           message_classifications: [
                                                                                                               FactoryGirl.create(:message_classification, {
                                                                                                                                                             classification: MessageClassification::ASK_DATE_SUGGESTIONS,
                                                                                                                                                             created_at: "2016-01-20",
                                                                                                                                                             summary: "Skype scheduled on 2016-01-20",
                                                                                                                                                             thread_status: MessageClassification::THREAD_STATUS_SCHEDULING_WAITING_FOR_CONTACT,
                                                                                                                                                             appointment_nature: "skype",
                                                                                                                                                             attendees: [
                                                                                                                                                                 {
                                                                                                                                                                     'email' => "nmarlier@gmail.com",
                                                                                                                                                                     'isPresent' => 'true',
                                                                                                                                                                     'firstName' => "Nico",
                                                                                                                                                                     'lastName' => "M",
                                                                                                                                                                     'company' => "JD"
                                                                                                                                                                 }
                                                                                                                                                             ].to_json,
                                                                                                                                                             julie_action: FactoryGirl.create(:julie_action, {
                                                                                                                                                                                                               action_nature: JulieAction::JD_ACTION_SUGGEST_DATES,
                                                                                                                                                                                                               done: true,
                                                                                                                                                                                                           })
                                                                                                                                                         })
                                                                                                           ]
                                                                                                       })
                                                                        ]
                                                                    })

        @correct_scheduling_aborted_mt2 = FactoryGirl.create(:messages_thread, {
            account_email: "nicolas@juliedesk.com",
            subject: "Subject scheduling aborted mt 2",
            server_thread_id: 1,
            messages: [
                FactoryGirl.create(:message, {
                    received_at: "2016-01-17",
                    message_classifications: [
                        FactoryGirl.create(:message_classification, {
                            classification: MessageClassification::ASK_DATE_SUGGESTIONS,
                            created_at: "2016-01-17",
                            summary: "Skype scheduled on 2016-01-17",
                            thread_status: MessageClassification::THREAD_STATUS_SCHEDULING_WAITING_FOR_CONTACT,
                            appointment_nature: "skype",
                            attendees: [
                                {
                                    'email' => "nmarlier@gmail.com",
                                    'isPresent' => 'true',
                                    'firstName' => "Nico",
                                    'lastName' => "M",
                                    'company' => "JD"
                                }
                            ].to_json,
                            julie_action: FactoryGirl.create(:julie_action, {
                                action_nature: JulieAction::JD_ACTION_SUGGEST_DATES,
                                done: true,
                            })
                        })
                    ]
                })
            ]
        })

      end
      it "should behave correctly" do
        data = WeeklyRecapHelper.get_weekly_recap_data({
                                                           account_email: "nicolas@juliedesk.com",
                                                           start_of_week: DateTime.parse("2016-02-01")
                                                       })

        expect(data).to eq([
                               {
                                   :account_email=>"nicolas@juliedesk.com",
                                   :status => "scheduling",
                                   :subject => "Skype scheduled on 2016-02-03",
                                   :thread_subject => "Subject scheduling mt",
                                   :other =>
                                       {
                                           :id => @correct_scheduling_mt.id,
                                           :server_thread_id => 1,
                                           :waiting_for => "contact",
                                           :valid_suggestions_count => 0,
                                           :suggestions_count => 0,
                                           :appointment_nature => "skype",
                                           :attendees => [{email: "nmarlier@gmail.com", name: "Nico M", company: "JD"}],
                                           :last_message_received_at => "2016-02-03 00:00:00 UTC",
                                           :follow_up_reminder_date => nil
                                       }
                               },
                               {
                                   :account_email=>"nicolas@juliedesk.com",
                                   :status => "scheduling",
                                   :subject => "Skype scheduled on 2016-01-20",
                                   :thread_subject => "Subject scheduling aborted mt",
                                   :other =>
                                       {
                                           :id => @correct_scheduling_aborted_mt1.id,
                                           :server_thread_id => 1,
                                           :waiting_for => "contact",
                                           :valid_suggestions_count => 0,
                                           :suggestions_count => 0,
                                           :appointment_nature => "skype",
                                           :attendees => [{email: "nmarlier@gmail.com", name: "Nico M", company: "JD"}],
                                           :last_message_received_at => "2016-01-20 00:00:00 UTC",
                                           :follow_up_reminder_date => nil
                                       }
                               },
                               {
                                   :account_email=>"nicolas@juliedesk.com",
                                   :status=>"aborted",
                                   :subject=>"Skype scheduled on 2016-01-17",
                                   :thread_subject => "Subject scheduling aborted mt 2",
                                   :other=>
                                       {
                                           :id=>@correct_scheduling_aborted_mt2.id,
                                           :server_thread_id => 1,
                                           :last_message_received_at=>"2016-01-17 00:00:00 UTC",
                                           :appointment_nature=>"skype",
                                           :attendees=>[
                                               {email: "nmarlier@gmail.com", :name=>"Nico M", :company=>"JD"}
                                           ]
                                       }
                               }
                           ])
      end
    end

    describe "aborted" do
      before do

        @correct_aborted_mt = FactoryGirl.create(:messages_thread, {
                                                                     account_email: "nicolas@juliedesk.com",
                                                                     subject: "Subject aborted mt",
                                                                     server_thread_id: 1,
                                                                     messages: [
                                                                         FactoryGirl.create(:message, {
                                                                                                        received_at: "2016-02-03",
                                                                                                        message_classifications: [
                                                                                                            FactoryGirl.create(:message_classification, {
                                                                                                                                                          classification: MessageClassification::ASK_CANCEL_APPOINTMENT,
                                                                                                                                                          created_at: "2016-02-03",
                                                                                                                                                          summary: "Skype canceled on 2016-02-03",
                                                                                                                                                          thread_status: MessageClassification::THREAD_STATUS_SCHEDULING_ABORTED,
                                                                                                                                                          appointment_nature: "skype",
                                                                                                                                                          attendees: [
                                                                                                                                                              {
                                                                                                                                                                  'email' => "nmarlier@gmail.com",
                                                                                                                                                                  'isPresent' => 'true',
                                                                                                                                                                  'firstName' => "Nico",
                                                                                                                                                                  'lastName' => "M",
                                                                                                                                                                  'company' => "JD"
                                                                                                                                                              }
                                                                                                                                                          ].to_json,
                                                                                                                                                          julie_action: FactoryGirl.create(:julie_action, {
                                                                                                                                                                                                            action_nature: JulieAction::JD_ACTION_CREATE_EVENT,
                                                                                                                                                                                                            done: true,
                                                                                                                                                                                                            events: [
                                                                                                                                                                                                                {
                                                                                                                                                                                                                    event_id: "event_id_1",
                                                                                                                                                                                                                    calendar_id: "calendar_id_1",
                                                                                                                                                                                                                    event_url: "event_url_1",
                                                                                                                                                                                                                    calendar_login_username: "calendar_login_username_1",
                                                                                                                                                                                                                }
                                                                                                                                                                                                            ].to_json
                                                                                                                                                                                                        })
                                                                                                                                                      })
                                                                                                        ]
                                                                                                    })
                                                                     ]
                                                                 })

      end
      it "should behave correctly" do
        data = WeeklyRecapHelper.get_weekly_recap_data({
                                                           account_email: "nicolas@juliedesk.com",
                                                           start_of_week: DateTime.parse("2016-02-01")
                                                       })

        expect(data).to eq([
                               {
                                   :account_email=>"nicolas@juliedesk.com",
                                   :status=>"aborted",
                                   :subject=>"Skype canceled on 2016-02-03",
                                   :thread_subject => "Subject aborted mt",
                                   :other=>
                                       {
                                           :id=>@correct_aborted_mt.id,
                                           :server_thread_id => 1,
                                           :last_message_received_at=>"2016-02-03 00:00:00 UTC",
                                           :appointment_nature=>"skype",
                                           :attendees=>[
                                               {email: "nmarlier@gmail.com", :name=>"Nico M", :company=>"JD"}
                                           ]
                                       }
                               }
                           ])
      end
    end

  end



end