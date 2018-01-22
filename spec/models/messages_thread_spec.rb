require "rails_helper"

describe MessagesThread, :type => :model do
  before do
    @messages_thread = FactoryGirl.create(:messages_thread)

    @account = Account.new
    @account.locale =  "en"
    @account.default_timezone_id = "America/Los_Angeles"
    @account.appointments = []
    @account.calendar_logins = []


    allow_any_instance_of(MessagesThread).to receive(:calendar_login).and_return(nil)

    @message_classification_params = {
        ask_availabilities_1: {
            classification: MessageClassification::ASK_AVAILABILITIES,
            locale: "fr",
            timezone: "Europe/Paris",
            appointment_nature: "meeting",
            summary: "Hello",
            duration: 30,
            location_nature: "office",
            location: "9 rue Dareau",
            attendees: "[]",
            notes: "Nico number: 678",
            other_notes: "",
            private: false,
            client_agreement: true,
            attendees_are_noticed: true,
            constraints: "",
            constraints_data: "[]",
            date_times: [{date: "2015-03-06T12:15:00+00:00", timezone: "Europe/Paris"}].to_json
        },
        ask_availabilities_2: {
            classification: MessageClassification::ASK_AVAILABILITIES,
            locale: "en",
            timezone: "America/Los_Angeles",
            appointment_nature: "call",
            summary: "Call Nico",
            duration: 45,
            location_nature: nil,
            location: "",
            attendees: "[]",
            notes: "Nico number: 678890",
            other_notes: "Notes",
            private: false,
            client_agreement: true,
            attendees_are_noticed: true,
            constraints: "",
            constraints_data: "[]",
            date_times: [{date: "2015-03-07T14:15:00+00:00", timezone: "America/Los_Angeles"}].to_json
        },
        create_events_1: {
            classification: MessageClassification::ASK_CREATE_EVENT
        },
        free_answer_1: {
            classification: MessageClassification::UNKNOWN
        },
    }

    @julie_action_params = {
        no_creation_1: {
            done: true,
        },
        creation_0: {
            action_nature: JulieAction::JD_ACTION_CREATE_EVENT,
            done: true,
            events: "[{\"id\":\"6997703\"}]"
        },
        creation_1: {
            done: true,
            event_id: "eid1",
            calendar_id: "cid1",
            calendar_login_username: "google.nmarlier@gmail.com"
        },
        creation_2: {
            done: true,
            event_id: "eid2",
            calendar_id: "cid2",
            calendar_login_username: "icloud.nmarlier@gmail.com"
        },
        deletion_1: {
            done: true,
            deleted_event: true
        },
        free_action_1: {
            done: true,
            action_nature: "free_action"
        }

    }
  end


  # Scopes
  describe '.with_this_client' do
    let(:account_email) { "" }
    let(:clients_in_recipients) { [account_email] }
    let!(:messages_thread) { create(:messages_thread, clients_in_recipients: clients_in_recipients) }

    subject { MessagesThread.with_this_client(account_email).count }

    context 'when no thread with this client' do
      let(:account_email) { "bob@juliedesk.com" }
      let(:clients_in_recipients) { ["john@juliedesk.com"] }

      it { is_expected.to eq(0) }
    end

    context 'when there is a thread with this client' do
      let(:account_email) { "bob@juliedesk.com" }
      it { is_expected.to eq(1) }
    end
  end


  describe '.syncing' do
    let(:tags) { [] }
    let!(:messages_thread) { create(:messages_thread, tags: tags) }

    subject { MessagesThread.syncing.count }

    context 'when no thread has syncing tag' do
      it { is_expected.to eq(0) }
    end

    context 'when a thread has syncing tag' do
      let(:tags) { [MessagesThread::SYNCING_TAG] }
      it { is_expected.to eq(1) }
    end
  end

  describe '.not_syncing' do
    let(:tags) { [] }
    let!(:messages_thread) { create(:messages_thread, tags: tags) }

    subject { MessagesThread.not_syncing.count }

    context 'when thread has no tag' do
      it { is_expected.to eq(2) }
    end

    context 'when thread has syncing tag' do
      let(:tags) { [MessagesThread::SYNCING_TAG] }
      it { is_expected.to eq(1) }
    end
  end

  describe "#virtual_appointment_natures" do
    it "should return virtual appointment natures" do
      expect(MessagesThread.virtual_appointment_natures).to eq(["skype", "call", "webex", "confcall", "hangout", "visio"])
    end
  end

  describe "#computed_data" do
    context "empty messages_thread" do
      before do

      end
      it "should return empty data" do
        expect(@messages_thread.computed_data).to eq({
                                                        :locale => nil,
                                                        :timezone => nil,
                                                        :appointment_nature => nil,
                                                        :summary => nil,
                                                        :duration => 60,
                                                        :location_nature => nil,
                                                        :location => nil,
                                                        :location_coordinates=>nil,
                                                        :call_instructions=>[],
                                                        :attendees => [],
                                                        :notes => nil,
                                                        :other_notes => nil,
                                                        :is_virtual_appointment => false,
                                                        :private => nil,
                                                        :client_agreement => nil,
                                                        :client_on_trip => nil,
                                                        :cluster_specified_location => nil,
                                                        :attendees_are_noticed => nil,
                                                        :constraints => nil,
                                                        :constraints_data => [],
                                                        :number_to_call => nil,
                                                        :date_times => [],
                                                        :last_message_sent_at => nil,
                                                        :calendar_login_username => nil,
                                                        :calendar_login_type => nil,
                                                        :title_preference=>nil,
                                                        :using_meeting_room=>nil,
                                                        :meeting_room_details=>nil,
                                                        :booked_rooms_details=>nil,
                                                        :using_restaurant_booking=>nil,
                                                        :restaurant_booking_details=>nil,
                                                        :virtual_resource_used=>nil,
                                                        :thread_recipients=>[],
                                                        :linked_attendees=>{},
                                                        :do_not_ask_suggestions => false,
                                                        :language_level => :normal,
                                                        :trusted_attendees=>{},
                                                        :asap_constraint => false,
                                                        :auto_follow_up_enabled=>false,
                                                        :allowed_attendees=>[],
                                                        :date_suggestions_full_ai => false
                                                    })
      end
    end

    context "empty messages_thread and account" do
      before do
        @messages_thread.instance_variable_set(:@account, @account)
      end
      it "should return empty data with account defaults" do
        expect(@messages_thread.computed_data).to eq({
                                                        :locale => "en",
                                                        :timezone => "America/Los_Angeles",
                                                        :appointment_nature => nil,
                                                        :summary => nil,
                                                        :duration => 60,
                                                        :location_nature => nil,
                                                        :location => nil,
                                                        :location_coordinates=>nil,
                                                        :call_instructions=>[],
                                                        :attendees => [],
                                                        :notes => nil,
                                                        :other_notes => nil,
                                                        :is_virtual_appointment => false,
                                                        :private => nil,
                                                        :client_agreement => nil,
                                                        :client_on_trip => nil,
                                                        :cluster_specified_location => nil,
                                                        :attendees_are_noticed => nil,
                                                        :constraints => nil,
                                                        :constraints_data => [],
                                                        :number_to_call => nil,
                                                        :date_times => [],
                                                        :last_message_sent_at => nil,
                                                        :calendar_login_username => nil,
                                                        :calendar_login_type => nil,
                                                        :title_preference=>nil,
                                                        :using_meeting_room=>nil,
                                                        :meeting_room_details=>nil,
                                                        :booked_rooms_details=>nil,
                                                        :using_restaurant_booking=>nil,
                                                        :restaurant_booking_details=>nil,
                                                        :virtual_resource_used=>nil,
                                                        :thread_recipients=>[],
                                                        :linked_attendees=>{},
                                                        :do_not_ask_suggestions => false,
                                                        :language_level => :normal,
                                                        :trusted_attendees=>{},
                                                        :asap_constraint => false,
                                                        :auto_follow_up_enabled=>false,
                                                        :allowed_attendees=>[],
                                                        :date_suggestions_full_ai => false,
                                                    })
      end
    end

    context "one message_classification" do
      before do
        message = @messages_thread.messages.create
        message.message_classifications.create(@message_classification_params[:ask_availabilities_1])
      end
      it "should return this message classification data" do
        expect(@messages_thread.computed_data).to eq({
                                                        :locale => "fr",
                                                        :timezone => "Europe/Paris",
                                                        :appointment_nature => "meeting",
                                                        :summary => "Hello",
                                                        :duration => 30,
                                                        :location_nature => "office",
                                                        :location => "9 rue Dareau",
                                                        :location_coordinates=>[],
                                                        :call_instructions=>[],
                                                        :attendees => [],
                                                        :notes => "Nico number: 678",
                                                        :other_notes => "",
                                                        :is_virtual_appointment => false,
                                                        :private => false,
                                                        :client_agreement => true,
                                                        :client_on_trip => nil,
                                                        :cluster_specified_location => nil,
                                                        :attendees_are_noticed => true,
                                                        :constraints => "",
                                                        :constraints_data => [],
                                                        :number_to_call => nil,
                                                        :date_times => [
                                                            {"date" => "2015-03-06T12:15:00+00:00", "timezone" => "Europe/Paris"},
                                                        ],
                                                        :last_message_sent_at => nil,
                                                        :calendar_login_username => nil,
                                                        :calendar_login_type => nil,
                                                        :title_preference=>nil,
                                                        :using_meeting_room=>false,
                                                        :meeting_room_details=>nil,
                                                        :booked_rooms_details=>nil,
                                                        :using_restaurant_booking=>false,
                                                        :restaurant_booking_details=>nil,
                                                        :virtual_resource_used=>nil,
                                                        :thread_recipients=>[],
                                                        :linked_attendees=>{},
                                                        :do_not_ask_suggestions => false,
                                                        :language_level => :normal,
                                                        :trusted_attendees=>{},
                                                        :asap_constraint => false,
                                                        :auto_follow_up_enabled=>false,
                                                        :allowed_attendees=>[],
                                                        :date_suggestions_full_ai => false,
                                                    })
      end
    end
    context "two message_classification" do
      before do
        message = @messages_thread.messages.create
        message.message_classifications.create(@message_classification_params[:ask_availabilities_1])
        message.message_classifications.create(@message_classification_params[:ask_availabilities_2])
      end
      it "should return the last message classification data" do
        expect(@messages_thread.computed_data).to eq({
                                                        :locale => "en",
                                                        :timezone => "America/Los_Angeles",
                                                        :appointment_nature => "call",
                                                        :summary => "Call Nico",
                                                        :duration => 45,
                                                        :location_nature => nil,
                                                        :location => "",
                                                        :location_coordinates=>[],
                                                        :call_instructions=>[],
                                                        :attendees => [],
                                                        :notes => "Nico number: 678890",
                                                        :other_notes => "Notes",
                                                        :is_virtual_appointment => true,
                                                        :private => false,
                                                        :client_agreement => true,
                                                        :client_on_trip => nil,
                                                        :cluster_specified_location => nil,
                                                        :attendees_are_noticed => true,
                                                        :constraints => "",
                                                        :constraints_data => [],
                                                        :number_to_call => nil,
                                                        :date_times => [
                                                            {"date" => "2015-03-06T12:15:00+00:00", "timezone" => "Europe/Paris"},
                                                            {"date" => "2015-03-07T14:15:00+00:00", "timezone" => "America/Los_Angeles"}
                                                        ],
                                                        :last_message_sent_at => nil,
                                                        :calendar_login_username => nil,
                                                        :calendar_login_type => nil,
                                                        :title_preference=>nil,
                                                        :using_meeting_room=>false,
                                                        :meeting_room_details=>nil,
                                                        :booked_rooms_details=>nil,
                                                        :using_restaurant_booking=>false,
                                                        :restaurant_booking_details=>nil,
                                                        :virtual_resource_used=>nil,
                                                        :thread_recipients=>[],
                                                        :linked_attendees=>{},
                                                        :do_not_ask_suggestions => false,
                                                        :language_level => :normal,
                                                        :trusted_attendees=>{},
                                                        :asap_constraint => false,
                                                        :auto_follow_up_enabled=>false,
                                                        :allowed_attendees=>[],
                                                        :date_suggestions_full_ai => false,
                                                    })
      end
    end

    context "two message_classification with a free_answer" do
      before do
        message1 = @messages_thread.messages.create
        message1.message_classifications.create(@message_classification_params[:ask_availabilities_2])
        message2 = @messages_thread.messages.create
        message2.message_classifications.create(@message_classification_params[:free_answer])
      end
      it "should return the last not free answer message classification data" do
        expect(@messages_thread.computed_data).to eq({
                                                        :locale => "en",
                                                        :timezone => "America/Los_Angeles",
                                                        :appointment_nature => "call",
                                                        :summary => "Call Nico",
                                                        :duration => 45,
                                                        :location_nature => nil,
                                                        :location => "",
                                                        :location_coordinates=>[],
                                                        :call_instructions=>[],
                                                        :attendees => [],
                                                        :notes => "Nico number: 678890",
                                                        :other_notes => "Notes",
                                                        :is_virtual_appointment => true,
                                                        :private => false,
                                                        :client_agreement => true,
                                                        :client_on_trip => nil,
                                                        :cluster_specified_location => nil,
                                                        :attendees_are_noticed => true,
                                                        :constraints => "",
                                                        :constraints_data => [],
                                                        :number_to_call => nil,
                                                        :date_times => [
                                                            {"date" => "2015-03-07T14:15:00+00:00", "timezone" => "America/Los_Angeles"}
                                                        ],
                                                        :last_message_sent_at => nil,
                                                        :calendar_login_username => nil,
                                                        :calendar_login_type => nil,
                                                        :title_preference=>nil,
                                                        :using_meeting_room=>false,
                                                        :meeting_room_details=>nil,
                                                        :booked_rooms_details=>nil,
                                                        :using_restaurant_booking=>false,
                                                        :restaurant_booking_details=>nil,
                                                        :virtual_resource_used=>nil,
                                                        :thread_recipients=>[],
                                                        :linked_attendees=>{},
                                                        :do_not_ask_suggestions => false,
                                                        :language_level => :normal,
                                                        :trusted_attendees=>{},
                                                        :asap_constraint => false,
                                                        :auto_follow_up_enabled=>false,
                                                        :allowed_attendees=>[],
                                                        :date_suggestions_full_ai => false,
                                                    })
      end
    end
  end

  describe "#event_data" do
    context "empty message_classification" do
      it "should return nil" do
        expect(@messages_thread.event_data).to eq({
                                                     event_id: nil,
                                                     calendar_id: nil,
                                                     appointment_nature: nil,
                                                     event_url: nil,
                                                     calendar_login_username: nil,
                                                     event_from_invitation: false,
                                                     event_from_invitation_organizer: nil
                                                 })
      end
    end

    context "message_classification with julie_actions but no creation" do
      before do
        message = @messages_thread.messages.create
        mc1 = message.message_classifications.create(@message_classification_params[:ask_availabilities_1])
        mc1.create_julie_action(@julie_action_params[:no_creation_1])
      end

      it "should return nil" do
        expect(@messages_thread.event_data).to eq({
                                                     event_id: nil,
                                                     calendar_id: nil,
                                                     event_url: nil,
                                                     appointment_nature: nil,
                                                     calendar_login_username: nil,
                                                     event_from_invitation: false,
                                                     event_from_invitation_organizer: nil
                                                 })
      end
    end

    context "message_classification with a creation as julie_action" do
      before do
        message1 = @messages_thread.messages.create
        mc1 = message1.message_classifications.create(@message_classification_params[:ask_availabilities_1])
        mc1.create_julie_action(@julie_action_params[:creation_1])
      end

      it "should return data" do
        expect(@messages_thread.event_data).to eq({
                                                     event_id: "eid1",
                                                     calendar_id: "cid1",
                                                     appointment_nature: "meeting",
                                                     event_url: nil,
                                                     calendar_login_username: "google.nmarlier@gmail.com",
                                                     event_from_invitation: false,
                                                     event_from_invitation_organizer: nil
                                                 })
      end
    end

    context "message_classification with two creations as julie_action" do
      before do
        message1 = @messages_thread.messages.create
        mc1 = message1.message_classifications.create(@message_classification_params[:ask_availabilities_1])
        mc1.create_julie_action(@julie_action_params[:creation_1])

        message2 = @messages_thread.messages.create
        mc2 = message2.message_classifications.create(@message_classification_params[:ask_availabilities_2])
        mc2.create_julie_action(@julie_action_params[:deletion_1])

        message3 = @messages_thread.messages.create
        mc3 = message3.message_classifications.create(@message_classification_params[:ask_availabilities_2])
        mc3.create_julie_action(@julie_action_params[:creation_2])
      end

      it "should return data" do
        expect(@messages_thread.event_data).to eq({
                                                     event_id: "eid2",
                                                     calendar_id: "cid2",
                                                     appointment_nature: "call",
                                                     event_url: nil,
                                                     calendar_login_username: "icloud.nmarlier@gmail.com",
                                                     event_from_invitation: false,
                                                     event_from_invitation_organizer: nil
                                                 })
      end
    end

    context "message_classification with a creation and a deletion" do
      before do
        message1 = @messages_thread.messages.create
        mc1 = message1.message_classifications.create(@message_classification_params[:ask_availabilities_1])
        mc1.create_julie_action(@julie_action_params[:creation_1])

        message2 = @messages_thread.messages.create
        mc2 = message2.message_classifications.create(@message_classification_params[:ask_availabilities_2])
        mc2.create_julie_action(@julie_action_params[:creation_2])

        message3 = @messages_thread.messages.create
        mc3 = message3.message_classifications.create(@message_classification_params[:ask_availabilities_2])
        mc3.create_julie_action(@julie_action_params[:deletion_1])
      end

      it "should return data" do
        expect(@messages_thread.event_data).to eq({
                                                     event_id: nil,
                                                     calendar_id: nil,
                                                     appointment_nature: nil,
                                                     event_url: nil,
                                                     calendar_login_username: nil,
                                                     event_from_invitation: false,
                                                     event_from_invitation_organizer: nil
                                                 })
      end
    end
  end

  describe "#scheduling_status" do
    context "empty messages_thread" do
      it "should be nil" do
        expect(@messages_thread.scheduling_status).to equal(nil)
      end
    end

    context "messages_thread with free reply" do
      before do
        message = @messages_thread.messages.create
        mc = message.message_classifications.create(@message_classification_params[:free_answer_1])
        mc.create_julie_action(@julie_action_params[:free_action_1])
      end
      it "should be nil" do
        expect(@messages_thread.scheduling_status).to equal(nil)
      end
    end

    context "messages_thread with suggest availabilities" do
      before do
        message = @messages_thread.messages.create
        mc = message.message_classifications.create(@message_classification_params[:ask_availabilities_1])
        mc.create_julie_action(@julie_action_params[:no_creation_1])
      end
      it "should be scheduling" do
        expect(@messages_thread.scheduling_status).to equal(MessagesThread::SCHEDULING_EVENT)
      end
    end

    context "messages_thread with create events" do
      before do
        message = @messages_thread.messages.create
        mc = message.message_classifications.create(@message_classification_params[:create_events_1])
        mc.create_julie_action(@julie_action_params[:creation_0])
      end
      it "should be events created" do
        expect(@messages_thread.scheduling_status).to equal(MessagesThread::EVENTS_CREATED)
      end
    end

    context "messages_thread with create events but events were deleted" do
      before do
        message = @messages_thread.messages.create
        mc = message.message_classifications.create(@message_classification_params[:create_events_1])
        mc.create_julie_action(@julie_action_params[:no_creation_1])
      end
      it "should be events created" do
        expect(@messages_thread.scheduling_status).to be(nil)
      end
    end

    context "messages_thread with event scheduled" do
      before do
        message = @messages_thread.messages.create
        mc = message.message_classifications.create(@message_classification_params[:ask_availabilities_1])
        mc.create_julie_action(@julie_action_params[:creation_1])
      end
      it "should be event scheduled" do
        expect(@messages_thread.scheduling_status).to equal(MessagesThread::EVENT_SCHEDULED)
      end
    end

    context "messages_thread with event unscheduled" do
      before do
        message_1 = @messages_thread.messages.create
        mc_1 = message_1.message_classifications.create(@message_classification_params[:ask_availabilities_1])
        mc_1.create_julie_action(@julie_action_params[:creation_1])

        message_2 = @messages_thread.messages.create
        mc_2 = message_1.message_classifications.create(@message_classification_params[:ask_availabilities_1])
        mc_2.create_julie_action(@julie_action_params[:deletion_1])
      end
      it "should be nil" do
        expect(@messages_thread.scheduling_status).to equal(MessagesThread::SCHEDULING_EVENT )
      end
    end
  end

  describe "julie_alias" do
    before do
      @julie_alias_1 = FactoryGirl.create(:julie_alias, email: "julie@wepopp.com")
      @julie_alias_2 = FactoryGirl.create(:julie_alias, email: "julie@wetime.com")
      @julie_alias_3 = FactoryGirl.create(:julie_alias, email: "julie@juliedesk.com")
    end
    context "no julie alias" do
      before do
        expect(@messages_thread).to receive(:julie_aliases).and_return([])
      end
      it "should return julie@juliedesk.com" do
        expect(@messages_thread.julie_alias.email).to eq("julie@juliedesk.com")
      end
    end

    context "got julie aliases" do
      before do
        expect(@messages_thread).to receive(:julie_aliases).and_return([
                                                                           @julie_alias_1,
                                                                           @julie_alias_2
                                                                       ])
      end
      it "should return the first detected" do
        expect(@messages_thread.julie_alias).to eq(@julie_alias_1)
      end
    end
  end

  describe 'has_already_processed_action_once' do
    context 'first time' do
      before(:each) do
        message = @messages_thread.messages.create
        message.message_classifications.create(@message_classification_params[:ask_availabilities_1])
      end

      it 'should return true' do
        expect(@messages_thread.has_already_processed_action_once(MessageClassification::ASK_AVAILABILITIES)).to be(false)
      end
    end

    context 'second time' do
      before(:each) do
        message = @messages_thread.messages.create
        message.message_classifications.create(@message_classification_params[:ask_availabilities_1])
        message2 = @messages_thread.messages.create
        message2.message_classifications.create(@message_classification_params[:ask_availabilities_2])
      end

      it 'should return true' do
        expect(@messages_thread.has_already_processed_action_once(MessageClassification::ASK_AVAILABILITIES)).to be(true)
      end
    end
  end

  describe '#compute_linked_attendees' do

    let(:accounts_cache) {
      {
          'client1@email.com' => {
              'email' => 'client1@email.com',
              'email_aliases' => [],
              'linked_attendees_enabled' => true,
              'subscribed' => true,
              'configured' => true
          },
          'client2@email.com' => {
              'email' => 'client2@email.com',
              'email_aliases' => [],
              'linked_attendees_enabled' => true,
              'subscribed' => true,
              'configured' => true
          }
      }
    }

    before(:example) do
      allow(Account).to receive(:accounts_cache_for_email).with('client1@email.com').and_return({
                                                                                                    'email' => 'client1@email.com',
                                                                                                    'email_aliases' => [],
                                                                                                    'linked_attendees_enabled' => true,
                                                                                                    'subscribed' => true,
                                                                                                    'configured' => true
                                                                                                })
      allow(Account).to receive(:accounts_cache_for_email).with('client2@email.com').and_return({
                                                                                                    'email' => 'client2@email.com',
                                                                                                    'email_aliases' => [],
                                                                                                    'linked_attendees_enabled' => true,
                                                                                                    'subscribed' => true,
                                                                                                    'configured' => true
                                                                                                })
      @messages_thread.account_email = 'client1@email.com'
    end

    context 'multiple clients on the thread with linked attendees feature enabled' do
      before(:example) do
        @messages_thread.computed_recipients = ['client1@email.com', 'client2@email.com', 'attendee1@email.com', 'attendee2@email.com']
        @messages_thread.clients_in_recipients = ['client1@email.com', 'client2@email.com']

        http_response = double('http_response')
        allow(http_response).to receive(:code).and_return(200)
        allow(http_response).to receive(:parse).and_return({"client1@email.com"=>["attendee1@email.com"], "client2@email.com"=>["attendee2@email.com"]})
        allow_any_instance_of(HTTP::Client).to receive(:post).with('https://test-app.herokuapp.com/api/v1/linked_attendees/extract', {json: {clients_emails: ['client1@email.com', 'client2@email.com'], attendees_emails: ['attendee1@email.com', 'attendee2@email.com']}}).and_return(http_response)
      end

      it 'should populate the linked attendees field correctly' do
        @messages_thread.compute_linked_attendees(accounts_cache)
        expect(@messages_thread.linked_attendees).to eq({"client1@email.com"=>["attendee1@email.com"], "client2@email.com"=>["attendee2@email.com"]})
      end
    end

    context 'only the main client on the thread with linked attendees feature enabled' do
      before(:example) do
        @messages_thread.computed_recipients = ['client1@email.com', 'attendee1@email.com', 'attendee2@email.com']
        @messages_thread.clients_in_recipients = ['client1@email.com']
        http_response = double('http_response')
        allow(http_response).to receive(:code).and_return(200)
        allow(http_response).to receive(:parse).and_return({"client1@email.com"=>["attendee1@email.com"]})
        allow_any_instance_of(HTTP::Client).to receive(:post).with('https://test-app.herokuapp.com/api/v1/linked_attendees/extract', {json: {clients_emails: ['client1@email.com'], attendees_emails: ['attendee1@email.com', 'attendee2@email.com']}}).and_return(http_response)
      end

      it 'should populate the linked attendees field correctly' do
        @messages_thread.compute_linked_attendees(accounts_cache)
        expect(@messages_thread.linked_attendees).to eq({"client1@email.com"=>["attendee1@email.com"]})
      end
    end

    context 'attendees emails to check are forced' do
      let(:attendees_emails_to_check) { ['forced_attendees1@email.com', 'forced_attendees2@email.com'] }

      before(:example) do
        @messages_thread.computed_recipients = ['client1@email.com', 'attendee1@email.com', 'attendee2@email.com']
        @messages_thread.clients_in_recipients = ['client1@email.com']
        http_response = double('http_response')
        allow(http_response).to receive(:code).and_return(200)
        allow(http_response).to receive(:parse).and_return({'client1@email.com' =>['forced_attendees1@email.com', 'forced_attendees2@email.com']})
        allow_any_instance_of(HTTP::Client).to receive(:post).with('https://test-app.herokuapp.com/api/v1/linked_attendees/extract', {json: {clients_emails: ['client1@email.com'], attendees_emails: ['forced_attendees1@email.com', 'forced_attendees2@email.com']}}).and_return(http_response)
      end

      it 'should populate the linked attendees field correctly' do
        @messages_thread.compute_linked_attendees(accounts_cache, attendees_emails_to_check)
        expect(@messages_thread.linked_attendees).to eq({'client1@email.com' =>['forced_attendees1@email.com', 'forced_attendees2@email.com']})
      end
    end
  end

  describe '#ask_suggestions_needed?' do
    context 'when all recipients are clients' do
      it 'returns true' do
      end
    end

    context 'when all attendees are linked attendees or client' do
      it 'returns true' do
      end
    end

    context 'when one of the attendee is not a linked attendee nor a client' do
      it 'returns false' do
      end
    end
  end

  describe 'clients' do

    before(:example) do
      allow(Account).to receive(:accounts_cache_for_email).with('main_client@email.com').and_return({'email' => 'main_client@email.com', 'linked_attendees_enabled' => true, 'subscribed' => true})
      allow(Account).to receive(:accounts_cache_for_email).with('client1@email.com').and_return({'email' => 'client1@email.com', 'linked_attendees_enabled' => true, 'subscribed' => true})
      allow(Account).to receive(:accounts_cache_for_email).with('client2@email.com').and_return({'email' => 'client2@email.com', 'linked_attendees_enabled' => false, 'subscribed' => true})

      @messages_thread.clients_in_recipients = ['main_client@email.com', 'client1@email.com', 'client2@email.com']
    end

    it 'should return the correct clients accounts' do
      accounts = @messages_thread.clients

      expect(accounts.size).to eq(3)
      expect(accounts[0].email).to eq('main_client@email.com')
      expect(accounts[1].email).to eq('client1@email.com')
      expect(accounts[2].email).to eq('client2@email.com')
    end
  end

  describe 'get_clients_with_linked_attendees_enabled' do
    let(:accounts_cache) { {'client1@email.com' => {'email' => 'client1@email.com', 'linked_attendees_enabled' => true}, 'client2@email.com' => {'email' => 'client2@email.com', 'linked_attendees_enabled' => false}, 'main_client@email.com' => {'email' => 'main_client@email.com', 'linked_attendees_enabled' => true}} }

    before(:example) do
      allow(Account).to receive(:accounts_cache_for_email).with('main_client@email.com').and_return({'email' => 'main_client@email.com', 'linked_attendees_enabled' => true, 'subscribed' => true})
      allow(Account).to receive(:accounts_cache_for_email).with('client1@email.com').and_return({'email' => 'client1@email.com', 'linked_attendees_enabled' => true, 'subscribed' => true})
      allow(Account).to receive(:accounts_cache_for_email).with('client2@email.com').and_return({'email' => 'client2@email.com', 'linked_attendees_enabled' => false, 'subscribed' => true})

      @messages_thread.clients_in_recipients = ['main_client@email.com', 'client1@email.com', 'client2@email.com']
    end

    it 'should return the correct clients accounts' do
      accounts = @messages_thread.get_clients_with_linked_attendees_enabled

      expect(accounts.size).to eq(2)
      expect(accounts[0].email).to eq('main_client@email.com')
      expect(accounts[1].email).to eq('client1@email.com')
    end
  end

  describe 'should_reprocess_linked_attendees' do
    let(:computed_recipients_changed) { false }
    let(:accounts_cache) { {'client1@email.com' => {'linked_attendees_enabled' => false}, 'client2@email.com' => {'linked_attendees_enabled' => false}} }

    subject(:should_reprocess_linked_attendees) { @messages_thread.should_reprocess_linked_attendees(computed_recipients_changed) }

    context 'computed_recipients_changed' do
      let(:computed_recipients_changed) { true }

      context 'feature enabled' do
        before(:example) do
          allow(Account).to receive(:accounts_cache_for_email).with('client1@email.com').and_return({'linked_attendees_enabled' => true, 'subscribed' => true})
          allow(Account).to receive(:accounts_cache_for_email).with('client2@email.com').and_return({'linked_attendees_enabled' => false, 'subscribed' => true})
        end

        let(:accounts_cache) { {'client1@email.com' => {'linked_attendees_enabled' => true}, 'client2@email.com' => {'linked_attendees_enabled' => false}} }

        context 'single client' do
          before(:example) do
            @messages_thread.update(clients_in_recipients: ['client1@email.com'])
          end

          it 'should return be true' do
            expect(subject).to be(true)
          end
        end

        context 'multiple clients' do
          before(:example) do
            @messages_thread.update(clients_in_recipients: ['client1@email.com', 'client2@email.com'])
          end

          it 'should return be true' do
            expect(subject).to be(true)
          end
        end
      end

      context 'feature disabled' do
        before(:example) do
          allow(Account).to receive(:accounts_cache_for_email).with('client1@email.com').and_return({'linked_attendees_enabled' => false, 'subscribed' => true})
          allow(Account).to receive(:accounts_cache_for_email).with('client2@email.com').and_return({'linked_attendees_enabled' => false, 'subscribed' => true})
        end

        context 'single client' do
          before(:example) do
            @messages_thread.update(clients_in_recipients: ['client1@email.com'])
          end

          it 'should return be false' do
            expect(subject).to be(false)
          end
        end

        context 'multiple clients' do
          before(:example) do
            @messages_thread.update(clients_in_recipients: ['client1@email.com', 'client2@email.com'])
          end

          it 'should return be false' do
            expect(subject).to be(false)
          end
        end
      end

    end

    context 'computed_recipients_not_changed' do
      let(:computed_recipients_changed) { false }

      context 'feature enabled' do
        let(:accounts_cache) { {'client1@email.com' => {'linked_attendees_enabled' => true}, 'client2@email.com' => {'linked_attendees_enabled' => false}} }

        context 'single client' do
          before(:example) do
            @messages_thread.update(clients_in_recipients: ['client1@email.com'])
          end

          it 'should return be false' do
            expect(subject).to be(false)
          end
        end

        context 'multiple clients' do
          before(:example) do
            @messages_thread.update(clients_in_recipients: ['client1@email.com', 'client2@email.com'])
          end

          it 'should return be false' do
            expect(subject).to be(false)
          end
        end
      end


      context 'feature disabled' do
        context 'single client' do
          before(:example) do
            @messages_thread.update(clients_in_recipients: ['client1@email.com'])
          end

          it 'should return be false' do
            expect(subject).to be(false)
          end
        end

        context 'multiple clients' do
          before(:example) do
            @messages_thread.update(clients_in_recipients: ['client1@email.com', 'client2@email.com'])
          end

          it 'should return be false' do
            expect(subject).to be(false)
          end
        end
      end
    end
  end

  describe 'attendees_has_changed' do
    let(:messages_thread) { MessagesThread.new }
    subject(:attendees_changed?) { messages_thread.attendees_has_changed(old_attendees, new_attendees) }

    context 'attendees has not changed' do
      let(:new_attendees) { ['email1@email.com', 'email2@email.com'] }
      let(:old_attendees) { ['email1@email.com', 'email2@email.com'] }

      it 'should return true' do
        expect(attendees_changed?).to be(false)
      end
    end

    context 'attendees has changed' do
      let(:new_attendees) { ['email1@email.com', 'email2@email.com', 'email3@email.com'] }
      let(:old_attendees) { ['email1@email.com', 'email2@email.com'] }

      it 'should return false' do
        expect(attendees_changed?).to be(true)
      end
    end
  end

  describe 'check_recompute_linked_attendees' do
    before(:example) do
      @messages_thread.update(clients_in_recipients: ['client1@email.com'])
    end

    #subject(:should_reprocess_linked_attendees) { @messages_thread.check_recompute_linked_attendees(old_attendees, new_attendees) }

    context 'Client has the linked attendees feature active' do
      before(:example) do
        allow(Account).to receive(:accounts_cache_for_email).with('client1@email.com').and_return({'linked_attendees_enabled' => true, 'subscribed' => true})
      end

      context 'attendees  have changed' do
        let(:old_attendees) { {'1' => {'email' => 'email1@email.com'}, '2' => {'email' => 'email2@email.com'}} }
        let(:new_attendees) { {'1' => {'email' => 'email1@email.com', 'isPresent' => 'true'}, '2' => {'email' => 'email2@email.com', 'isPresent' => 'true'}, '3' => {'email' => 'email2@email.com', 'isPresent' => 'true'}} }

        it 'should recompute the linked attendees' do
          expect(@messages_thread).to receive(:compute_linked_attendees)
          @messages_thread.check_recompute_linked_attendees(old_attendees, new_attendees)
        end

      end

      context 'attendees have not changed' do
        let(:old_attendees) { {'1' => {'email' => 'email1@email.com'}, '2' => {'email' => 'email2@email.com'}} }
        let(:new_attendees) { {'1' => {'email' => 'email1@email.com', 'isPresent' => 'true'}, '2' => {'email' => 'email2@email.com', 'isPresent' => 'true'}} }

        it 'should not recompute the linked attendees' do
          expect(@messages_thread).not_to receive(:compute_linked_attendees)
          @messages_thread.check_recompute_linked_attendees(old_attendees, new_attendees)
        end
      end
    end

    context 'Client has not the linked attendees feature active' do
      before(:example) do
        allow(Account).to receive(:accounts_cache_for_email).with('client1@email.com').and_return({'linked_attendees_enabled' => false})
      end

      context 'attendees  have changed' do
        let(:old_attendees) { {'1' => {'email' => 'email1@email.com'}, '2' => {'email' => 'email2@email.com'}} }
        let(:new_attendees) { {'1' => {'email' => 'email1@email.com', 'isPresent' => 'true'}, '2' => {'email' => 'email2@email.com', 'isPresent' => 'true'}, '3' => {'email' => 'email2@email.com', 'isPresent' => 'true'}} }

        it 'should not recompute the linked attendees' do
          expect(@messages_thread).not_to receive(:compute_linked_attendees)
          @messages_thread.check_recompute_linked_attendees(old_attendees, new_attendees)
        end

      end

      context 'attendees have not changed' do
        let(:old_attendees) { {'1' => {'email' => 'email1@email.com'}, '2' => {'email' => 'email2@email.com'}} }
        let(:new_attendees) { {'1' => {'email' => 'email1@email.com', 'isPresent' => 'true'}, '2' => {'email' => 'email2@email.com', 'isPresent' => 'true'}} }

        it 'should not recompute the linked attendees' do
          expect(@messages_thread).not_to receive(:compute_linked_attendees)
          @messages_thread.check_recompute_linked_attendees(old_attendees, new_attendees)
        end
      end
    end
  end

  describe 'trusted_attendees' do

    before(:example) do
      allow(Account).to receive(:accounts_cache_for_email).with('client1@email.com').and_return({
                                                                                                    'full_name' => 'Client 1 Name',
                                                                                                    'subscribed' => true,
                                                                                                    'circle_of_trust' => {
                                                                                                        "trusting_everyone"=>false,
                                                                                                        "trusted_domains"=>["domain1.com", "domain2.com"],
                                                                                                        "trusted_emails"=>["email1@email.com", "email2@email.com"]
                                                                                                    }
                                                                                                })
      allow(Account).to receive(:accounts_cache_for_email).with('client2@email.com').and_return({
                                                                                                    'full_name' => 'Client 2 Name',
                                                                                                    'subscribed' => true,
                                                                                                    'circle_of_trust' => {
                                                                                                        "trusting_everyone"=>false,
                                                                                                        "trusted_domains"=>["domain3.com", "domain4.com"],
                                                                                                        "trusted_emails"=>["email3@email.com", "email4@email.com"]
                                                                                                    }
                                                                                                })
    end

    it 'should return the correct hash' do
      @messages_thread.update(clients_in_recipients: ['client1@email.com', 'client2@email.com'])

      expect(@messages_thread.trusted_attendees).to eq({"Client 1 Name"=>{"trusting_everyone"=>false, "trusted_domains"=>["domain1.com", "domain2.com"], "trusted_emails"=>["email1@email.com", "email2@email.com"]}, "Client 2 Name"=>{"trusting_everyone"=>false, "trusted_domains"=>["domain3.com", "domain4.com"], "trusted_emails"=>["email3@email.com", "email4@email.com"]}})
    end
  end

  describe '#send_to_admin' do
    let(:messages_thread_params) { {} }
    let(:messages_thread) { FactoryGirl.create(:messages_thread, messages_thread_params) }
    before(:each) {
      allow(EmailServer).to receive(:add_and_remove_labels)
      messages_thread.send_to_admin(message: 'some bug occured', operator: "Bob")
    }
    subject { messages_thread.reload.has_been_sent_to_admin }

    context 'when thread has never been sent to admin' do
      let(:messages_thread_params) { { has_been_sent_to_admin: false } }
      it { is_expected.to eq(true) }
    end

    context 'when thread has already been sent to admin' do
      let(:messages_thread_params) { { has_been_sent_to_admin: true } }
      it { is_expected.to eq(true) }
    end
  end

  describe 'only_in_inbox' do
    let(:messages_thread1) { FactoryGirl.create(:messages_thread_with_messages, in_inbox: true, messages_count: 3) }
    let(:messages_thread2) { FactoryGirl.create(:messages_thread_with_messages, in_inbox: true, messages_count: 5) }
    let(:messages_thread3) { FactoryGirl.create(:messages_thread_with_messages, in_inbox: false, should_follow_up: true) }

    before(:example) do
      i = 0
      messages_thread1.messages.each do |m|
        m.update(server_message_id: i)
        i += 1
      end

      messages_thread2.messages.each do |m|
        m.update(server_message_id: i)
        i +=1
      end
    end

    it 'should return the messages server_message_id of the threads that are present in the inbox' do
      expect(MessagesThread.only_in_inbox_messages_server_ids).to match_array([0, 1, 2, 3, 4, 5, 6, 7])
    end
  end

  describe '.add_syncing_tag' do
    let(:account_email) { "bob@juliedesk.com" }

    let(:thread_account_email) { account_email }
    let(:clients_in_recipients) { [thread_account_email] }
    let(:inbox_status) { true }
    let(:tags) { [] }
    let!(:messages_thread) { create(:messages_thread, in_inbox: inbox_status, account_email: thread_account_email, clients_in_recipients: clients_in_recipients, tags: tags) }

    before(:each) { MessagesThread.add_syncing_tag(account_email) }
    subject { messages_thread.reload.tags }

    context "when thread is owned by account" do
      it { is_expected.to include(MessagesThread::SYNCING_TAG) }
    end


    context "when thread include account in recipients" do
      let(:thread_account_email) { "john@juliedesk.com" }
      let(:clients_in_recipients) { ["john@juliedesk.com", "bob@juliedesk.com"]}
      it { is_expected.to include(MessagesThread::SYNCING_TAG) }
    end

    context "when thread does not include client in recipients" do
      let(:thread_account_email) { "john@juliedesk.com" }
      it { is_expected.not_to include(MessagesThread::SYNCING_TAG) }
    end

    context "when thread is not in inbox" do
      let(:inbox_status) { false }
      it { is_expected.not_to include(MessagesThread::SYNCING_TAG) }
    end

    context "when tag is already present" do
      let(:tags) { [MessagesThread::SYNCING_TAG] }
      it { is_expected.to eq([MessagesThread::SYNCING_TAG]) }
    end
  end

  describe '.remove_syncing_tag' do
    shared_context 'all_calendars_synced' do
      before(:each) { allow_any_instance_of(MessagesThread).to receive(:calendars_synced?).and_return(true) }
    end

    shared_context 'calendars_not_synced' do
      before(:each) { allow_any_instance_of(MessagesThread).to receive(:calendars_synced?).and_return(false) }
    end


    let(:account_email) { "bob@juliedesk.com" }
    let(:thread_account_email) { account_email }
    let(:clients_in_recipients) { [thread_account_email] }
    let(:inbox_status) { true }
    let!(:messages_thread) do
      create(:messages_thread,
             tags: [MessagesThread::SYNCING_TAG],
             in_inbox: inbox_status,
             account_email: thread_account_email,
             clients_in_recipients: clients_in_recipients
      )
    end

    subject { messages_thread.reload.tags }

    context "when thread is owned by account" do
      include_context 'all_calendars_synced'

      it 'removes syncing tag' do
        MessagesThread.remove_syncing_tag(account_email)
        is_expected.not_to include(MessagesThread::SYNCING_TAG)
      end
    end

    context "when thread include account in recipients" do
      include_context 'all_calendars_synced'
      let(:thread_account_email) { "john@juliedesk.com" }
      let(:clients_in_recipients) { ["john@juliedesk.com", "bob@juliedesk.com"]}
      it 'removes syncing tag' do
        MessagesThread.remove_syncing_tag(account_email)
        is_expected.not_to include(MessagesThread::SYNCING_TAG)
      end
    end

    context "when thread does not include client in recipients" do
      include_context 'all_calendars_synced'
      let(:thread_account_email) { "john@juliedesk.com" }

      it 'does not remove syncing tag' do
        MessagesThread.remove_syncing_tag(account_email)
        is_expected.to include(MessagesThread::SYNCING_TAG)
      end
    end

    context "when thread is not in inbox" do
      let(:inbox_status) { false }
      it 'does not remove syncing tag' do
        MessagesThread.remove_syncing_tag(account_email)
        is_expected.to include(MessagesThread::SYNCING_TAG)
      end
    end

    context "calendars are not synced" do
      include_context 'calendars_not_synced'

      it 'removes syncing tag' do
        MessagesThread.remove_syncing_tag(account_email)
        is_expected.to include(MessagesThread::SYNCING_TAG)
      end
    end
  end


  describe '#calendars_synced?' do
    let(:clients_in_recipients) { ["bob@juliedesk.com", "john@juliedesk.com"] }
    let(:messages_thread) { create(:messages_thread, clients_in_recipients: clients_in_recipients) }
    subject { messages_thread.calendars_synced? }

    context 'when no client in recipients' do
      let(:clients_in_recipients) { [] }
      it { is_expected.to eq(true) }
    end

    context 'when one of the client is not synced' do
      before(:example) do
        allow(Account).to receive(:is_synced?).with("bob@juliedesk.com").and_return(false)
        allow(Account).to receive(:is_synced?).with("john@juliedesk.com").and_return(true)
      end

      it { is_expected.to eq(false) }
    end

    context 'when all client are synced' do
      before(:example) { allow(Account).to receive(:is_synced?).with(anything).and_return(true) }
      it { is_expected.to eq(true) }
    end

  end


  describe '#add_tag' do
    let(:tag_to_add) { "" }
    let(:messages_thread) { create(:messages_thread) }
    subject { -> { messages_thread.add_tag(tag_to_add) } }

    context 'when tag is invalid' do
      let(:tag_to_add) { "unrecognized_tag" }
      it { is_expected.to raise_exception }
    end

    context 'when tag is "syncing"' do
      let(:tag_to_add) { MessagesThread::SYNCING_TAG }
      it "includes syncing tag" do
        is_expected.to change { messages_thread.tags }.from([]).to([MessagesThread::SYNCING_TAG])
      end
    end

    context 'when tag is already present' do
      let(:messages_thread) { create(:messages_thread, tags: [MessagesThread::SYNCING_TAG]) }
      let(:tag_to_add) { MessagesThread::SYNCING_TAG }

      it "does nothing" do
        messages_thread.add_tag(tag_to_add)
        expect(messages_thread.reload.tags).to eq([MessagesThread::SYNCING_TAG])
      end
    end

  end

  describe '#remove_tag' do
    let(:tag_to_remove) { "" }
    let(:messages_thread) { create(:messages_thread, tags: [MessagesThread::SYNCING_TAG]) }
    subject { -> { messages_thread.remove_tag(tag_to_remove) } }

    context 'when tag is invalid' do
      let(:tag_to_remove) { "unrecognized_tag" }
      it { is_expected.to raise_exception }
    end

    context 'when tag is "syncing"' do
      let(:tag_to_remove) { MessagesThread::SYNCING_TAG }
      it "includes syncing tag" do
        is_expected.to change { messages_thread.tags }.from([MessagesThread::SYNCING_TAG]).to([])
      end
    end
  end

  describe '#has_tag?' do
    let(:tag_to_check) { "" }
    let(:tags) { [] }
    let(:messages_thread) { create(:messages_thread, tags: tags) }
    subject { messages_thread.has_tag?(tag_to_check) }


    context 'when tags are nil' do
      let(:tag_to_check) { MessagesThread::SYNCING_TAG }
      let(:tags) { nil }
      it { is_expected.to eq(false) }
    end

    context 'when tag is present' do
      let(:tag_to_check) { MessagesThread::SYNCING_TAG }
      let(:tags) { [MessagesThread::SYNCING_TAG] }
      it { is_expected.to eq(true) }
    end

    context 'when tag is not present' do
      let(:tag_to_check) { MessagesThread::SYNCING_TAG }
      let(:tags) { [] }
      it { is_expected.to eq(false) }
    end
  end

  describe 'handle_recipients_lost_access' do
    let(:recipients) { ['recipient1@gmail.com'] }
    let(:messages_thread) { FactoryGirl.create(:messages_thread_with_messages, in_inbox: true, messages_count: 3, clients_in_recipients: recipients) }

    let(:users_with_lost_access) { ['recipient1@gmail.com', 'recipient2@gmail.com', 'recipient3@gmail.com'] }
    let(:accounts_cache) {
      {
          'recipient1@gmail.com' => {
              'email' => 'client1@email.com',
              'usage_name' => 'Recipient 1'
          },
          'client2@email.com' => {
              'email' => 'client2@email.com',
              'usage_name' => 'Recipient 2'
          }
      }
    }

    context 'With renew links' do
      context 'Locale is en' do
        before(:example) do
          I18n.locale = :en
        end

        it 'should enqueue the correct workers' do
          body = {blocking_users_emails: ['recipient1@gmail.com'], originated_from_thread_id: messages_thread.id}
          expect(ADMIN_API_INTERFACE).to receive(:build_request).with(:get_blocking_users_calendars_renew_links, body).and_return({'recipient1@gmail.com' => [['Google', 'https://test.renew']]})
          expect(AutoEmailWorker).to receive(:enqueue).with(
              messages_thread.messages.sort_by(&:updated_at).last.id,
              AutomaticsEmails::Rules::TYPE_ACCESS_LOST_IN_THREAD_NATIVE_CONNEXION,
              {
                  key: 'blocked_request_notification.with_renew_links.body',
                  client_name: 'Recipient 1',
                  links_to_renew: "<li>calendar Google : https://test.renew</li>",
                  count: 1
              },
              'recipient1@gmail.com'
          )
          messages_thread.handle_recipients_lost_access(users_with_lost_access, accounts_cache)
        end
      end

      context 'Locale is fr' do
        before(:example) do
          I18n.locale = :fr
        end

        it 'should enqueue the correct workers' do
          body = {blocking_users_emails: ['recipient1@gmail.com'], originated_from_thread_id: messages_thread.id}
          expect(ADMIN_API_INTERFACE).to receive(:build_request).with(:get_blocking_users_calendars_renew_links, body).and_return({'recipient1@gmail.com' => [['Google', 'https://test.renew']]})
          expect(AutoEmailWorker).to receive(:enqueue).with(
              messages_thread.messages.sort_by(&:updated_at).last.id,
              AutomaticsEmails::Rules::TYPE_ACCESS_LOST_IN_THREAD_NATIVE_CONNEXION,
              {
                  key: 'blocked_request_notification.with_renew_links.body',
                  client_name: 'Recipient 1',
                  links_to_renew: "<li>calendrier Google : https://test.renew</li>",
                  count: 1
              },
              'recipient1@gmail.com'
          )
          messages_thread.handle_recipients_lost_access(users_with_lost_access, accounts_cache)
        end
      end
    end

    context 'With julie sharing' do
      it 'should enqueue the correct workers' do
        body = {blocking_users_emails: ['recipient1@gmail.com'], originated_from_thread_id: messages_thread.id}
        expect(ADMIN_API_INTERFACE).to receive(:build_request).with(:get_blocking_users_calendars_renew_links, body).and_return({'recipient1@gmail.com' => [['Exchange', 'julie_sharing']]})
        expect(AutoEmailWorker).to receive(:enqueue).with(
          messages_thread.messages.sort_by(&:updated_at).last.id,
          AutomaticsEmails::Rules::TYPE_ACCESS_LOST_IN_THREAD_SHARED_CONNEXION,
          {
            key: 'blocked_request_notification.with_calendar_sharing.body',
            client_name: 'Recipient 1'
          },
          'recipient1@gmail.com'
        )
        messages_thread.handle_recipients_lost_access(users_with_lost_access, accounts_cache)
      end
    end

    context 'With renew links plus julie sharing' do
      before(:example) do
        I18n.locale = :en
      end
      
      it 'should enqueue the correct workers' do
        body = {blocking_users_emails: ['recipient1@gmail.com'], originated_from_thread_id: messages_thread.id}
        expect(ADMIN_API_INTERFACE).to receive(:build_request).with(:get_blocking_users_calendars_renew_links, body).and_return({'recipient1@gmail.com' => [['Google', 'https://test.renew'], ['Exchange', 'julie_sharing']]})
        expect(AutoEmailWorker).to receive(:enqueue).with(
          messages_thread.messages.sort_by(&:updated_at).last.id,
          AutomaticsEmails::Rules::TYPE_ACCESS_LOST_IN_THREAD_NATIVE_CONNEXION,
          {
            key: 'blocked_request_notification.with_renew_links.body',
            client_name: 'Recipient 1',
            links_to_renew: "<li>calendar Google : https://test.renew</li>",
            count: 1
          },
          'recipient1@gmail.com'
        )

        expect(AutoEmailWorker).to receive(:enqueue).with(
          messages_thread.messages.sort_by(&:updated_at).last.id,
          AutomaticsEmails::Rules::TYPE_ACCESS_LOST_IN_THREAD_SHARED_CONNEXION,
          {
            key: 'blocked_request_notification.with_calendar_sharing.body',
            client_name: 'Recipient 1'
          },
          'recipient1@gmail.com'
        )
        messages_thread.handle_recipients_lost_access(users_with_lost_access, accounts_cache)
      end
    end
  end
end