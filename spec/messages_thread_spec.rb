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
                                                        :using_restaurant_booking=>nil,
                                                        :restaurant_booking_details=>nil,
                                                        :virtual_resource_used=>nil,
                                                        :thread_recipients=>[],
                                                        :linked_attendees=>{},
                                                        :do_not_ask_suggestions => false,
                                                        :language_level => :normal
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
                                                        :using_restaurant_booking=>nil,
                                                        :restaurant_booking_details=>nil,
                                                        :virtual_resource_used=>nil,
                                                        :thread_recipients=>[],
                                                        :linked_attendees=>{},
                                                        :do_not_ask_suggestions => false,
                                                        :language_level => :normal
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
                                                        :using_restaurant_booking=>false,
                                                        :restaurant_booking_details=>nil,
                                                        :virtual_resource_used=>nil,
                                                        :thread_recipients=>[],
                                                        :linked_attendees=>{},
                                                        :do_not_ask_suggestions => false,
                                                        :language_level => :normal
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
                                                        :using_restaurant_booking=>false,
                                                        :restaurant_booking_details=>nil,
                                                        :virtual_resource_used=>nil,
                                                        :thread_recipients=>[],
                                                        :linked_attendees=>{},
                                                        :do_not_ask_suggestions => false,
                                                        :language_level => :normal
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
                                                        :using_restaurant_booking=>false,
                                                        :restaurant_booking_details=>nil,
                                                        :virtual_resource_used=>nil,
                                                        :thread_recipients=>[],
                                                        :linked_attendees=>{},
                                                        :do_not_ask_suggestions => false,
                                                        :language_level => :normal
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
        mc.create_julie_action(@julie_action_params[:no_creation_1])
      end
      it "should be events created" do
        expect(@messages_thread.scheduling_status).to equal(MessagesThread::EVENTS_CREATED)
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

    # before(:example) do
    #   allow(Account).to receive(:find_account_email).with('client1@email.com', {:accounts_cache=>{}}).and_return('client1@email.com')
    #   allow(Account).to receive(:find_account_email).with('client2@email.com', {:accounts_cache=>{}}).and_return('client2@email.com')
    #   allow(Account).to receive(:find_account_email).with('attendee1@email.com', {:accounts_cache=>{}}).and_return(nil)
    #
    #   http_response = double('http_response')
    #   allow(http_response).to receive(:code).and_return(200)
    #   allow(http_response).to receive(:parse).and_return({"frederic@juliedesk.com"=>[], "stagingjuliedesk@gmail.com"=>["nicolas@jdesk.onmicrosoft.com", "justine@jdesk.onmicrosoft.com"]})
    #
    #   allow_any_instance_of(HTTP::Client).to receive(:post).with('https://test-app.herokuapp.com/api/v1/linked_attendees/extract', {json: {clients_emails: ['client1@email.com', 'client2@email.com'], attendees_emails: ['attendee1@email.com']}}).and_return(http_response)
    #   @messages_thread.computed_recipients = ['client1@email.com', 'client2@email.com', 'attendee1@email.com']
    #   @messages_thread.account_email = 'client1@email.com'
    # end

    before(:example) do
      allow(Account).to receive(:find_account_email).with('client1@email.com', {:accounts_cache=>{}}).and_return('client1@email.com')
      allow(Account).to receive(:find_account_email).with('client2@email.com', {:accounts_cache=>{}}).and_return('client2@email.com')
      allow(Account).to receive(:find_account_email).with('attendee1@email.com', {:accounts_cache=>{}}).and_return(nil)

      http_response = double('http_response')
      allow(http_response).to receive(:code).and_return(200)
      allow(http_response).to receive(:parse).and_return({"client1@email.com"=>["attendee1@email.com"]})

      allow_any_instance_of(HTTP::Client).to receive(:post).with('https://test-app.herokuapp.com/api/v1/linked_attendees/extract', {json: {clients_emails: ['client1@email.com'], attendees_emails: ['attendee1@email.com']}}).and_return(http_response)
      @messages_thread.computed_recipients = ['client1@email.com', 'client2@email.com', 'attendee1@email.com']
      @messages_thread.account_email = 'client1@email.com'
    end

    it 'should populate the linked attendees field correctly' do
      pending 'When implementing multiple clients support (main + secondary)'
      @messages_thread.compute_linked_attendees({})
      expect(@messages_thread.linked_attendees).to eq({"frederic@juliedesk.com"=>[], "stagingjuliedesk@gmail.com"=>["nicolas@jdesk.onmicrosoft.com", "justine@jdesk.onmicrosoft.com"]})
    end

    it 'should populate the linked attendees field correctly' do
      @messages_thread.compute_linked_attendees({})
      expect(@messages_thread.linked_attendees).to eq({"client1@email.com"=>["attendee1@email.com"]})
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
end