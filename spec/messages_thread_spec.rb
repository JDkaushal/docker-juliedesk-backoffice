require "rails_helper"

describe MessagesThread, :type => :model do
  before do
    MessagesThread.delete_all
    Message.delete_all
    MessageClassification.delete_all
    @message_thread = MessagesThread.create

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
      expect(MessagesThread.virtual_appointment_natures).to eq(["skype", "call", "webex"])
    end
  end

  describe "#computed_data" do
    context "empty messages_thread" do
      before do

      end
      it "should return empty data" do
        expect(@message_thread.computed_data).to eq({
                                                        :locale => nil,
                                                        :timezone => nil,
                                                        :appointment_nature => nil,
                                                        :summary => nil,
                                                        :duration => 60,
                                                        :location_nature => nil,
                                                        :location => nil,
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
                                                        :calendar_login_type => nil
                                                    })
      end
    end

    context "empty messages_thread and account" do
      before do
        @message_thread.instance_variable_set(:@account, @account)
      end
      it "should return empty data with account defaults" do
        expect(@message_thread.computed_data).to eq({
                                                        :locale => "en",
                                                        :timezone => "America/Los_Angeles",
                                                        :appointment_nature => nil,
                                                        :summary => nil,
                                                        :duration => 60,
                                                        :location_nature => nil,
                                                        :location => nil,
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
                                                        :calendar_login_type => nil
                                                    })
      end
    end

    context "one message_classification" do
      before do
        message = @message_thread.messages.create
        message.message_classifications.create(@message_classification_params[:ask_availabilities_1])
      end
      it "should return this message classification data" do
        expect(@message_thread.computed_data).to eq({
                                                        :locale => "fr",
                                                        :timezone => "Europe/Paris",
                                                        :appointment_nature => "meeting",
                                                        :summary => "Hello",
                                                        :duration => 30,
                                                        :location_nature => "office",
                                                        :location => "9 rue Dareau",
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
                                                        :calendar_login_type => nil
                                                    })
      end
    end
    context "two message_classification" do
      before do
        message = @message_thread.messages.create
        message.message_classifications.create(@message_classification_params[:ask_availabilities_1])
        message.message_classifications.create(@message_classification_params[:ask_availabilities_2])
      end
      it "should return the last message classification data" do
        expect(@message_thread.computed_data).to eq({
                                                        :locale => "en",
                                                        :timezone => "America/Los_Angeles",
                                                        :appointment_nature => "call",
                                                        :summary => "Call Nico",
                                                        :duration => 45,
                                                        :location_nature => nil,
                                                        :location => "",
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
                                                        :calendar_login_type => nil
                                                    })
      end
    end

    context "two message_classification with a free_answer" do
      before do
        message1 = @message_thread.messages.create
        message1.message_classifications.create(@message_classification_params[:ask_availabilities_2])
        message2 = @message_thread.messages.create
        message2.message_classifications.create(@message_classification_params[:free_answer])
      end
      it "should return the last not free answer message classification data" do
        expect(@message_thread.computed_data).to eq({
                                                        :locale => "en",
                                                        :timezone => "America/Los_Angeles",
                                                        :appointment_nature => "call",
                                                        :summary => "Call Nico",
                                                        :duration => 45,
                                                        :location_nature => nil,
                                                        :location => "",
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
                                                        :calendar_login_type => nil
                                                    })
      end
    end
  end

  describe "#event_data" do
    context "empty message_classification" do
      it "should return nil" do
        expect(@message_thread.event_data).to eq({
                                                     event_id: nil,
                                                     calendar_id: nil,
                                                     appointment_nature: nil,
                                                     event_url: nil,
                                                     calendar_login_username: nil
                                                 })
      end
    end

    context "message_classification with julie_actions but no creation" do
      before do
        message = @message_thread.messages.create
        mc1 = message.message_classifications.create(@message_classification_params[:ask_availabilities_1])
        mc1.create_julie_action(@julie_action_params[:no_creation_1])
      end

      it "should return nil" do
        expect(@message_thread.event_data).to eq({
                                                     event_id: nil,
                                                     calendar_id: nil,
                                                     event_url: nil,
                                                     appointment_nature: nil,
                                                     calendar_login_username: nil
                                                 })
      end
    end

    context "message_classification with a creation as julie_action" do
      before do
        message1 = @message_thread.messages.create
        mc1 = message1.message_classifications.create(@message_classification_params[:ask_availabilities_1])
        mc1.create_julie_action(@julie_action_params[:creation_1])
      end

      it "should return data" do
        expect(@message_thread.event_data).to eq({
                                                     event_id: "eid1",
                                                     calendar_id: "cid1",
                                                     appointment_nature: "meeting",
                                                     event_url: nil,
                                                     calendar_login_username: "google.nmarlier@gmail.com"
                                                 })
      end
    end

    context "message_classification with two creations as julie_action" do
      before do
        message1 = @message_thread.messages.create
        mc1 = message1.message_classifications.create(@message_classification_params[:ask_availabilities_1])
        mc1.create_julie_action(@julie_action_params[:creation_1])

        message2 = @message_thread.messages.create
        mc2 = message2.message_classifications.create(@message_classification_params[:ask_availabilities_2])
        mc2.create_julie_action(@julie_action_params[:deletion_1])

        message3 = @message_thread.messages.create
        mc3 = message3.message_classifications.create(@message_classification_params[:ask_availabilities_2])
        mc3.create_julie_action(@julie_action_params[:creation_2])
      end

      it "should return data" do
        expect(@message_thread.event_data).to eq({
                                                     event_id: "eid2",
                                                     calendar_id: "cid2",
                                                     appointment_nature: "call",
                                                     event_url: nil,
                                                     calendar_login_username: "icloud.nmarlier@gmail.com"
                                                 })
      end
    end

    context "message_classification with a creation and a deletion" do
      before do
        message1 = @message_thread.messages.create
        mc1 = message1.message_classifications.create(@message_classification_params[:ask_availabilities_1])
        mc1.create_julie_action(@julie_action_params[:creation_1])

        message2 = @message_thread.messages.create
        mc2 = message2.message_classifications.create(@message_classification_params[:ask_availabilities_2])
        mc2.create_julie_action(@julie_action_params[:creation_2])

        message3 = @message_thread.messages.create
        mc3 = message3.message_classifications.create(@message_classification_params[:ask_availabilities_2])
        mc3.create_julie_action(@julie_action_params[:deletion_1])
      end

      it "should return data" do
        expect(@message_thread.event_data).to eq({
                                                     event_id: nil,
                                                     calendar_id: nil,
                                                     appointment_nature: nil,
                                                     event_url: nil,
                                                     calendar_login_username: nil
                                                 })
      end
    end
  end

  describe "#scheduling_status" do
    context "empty messages_thread" do
      it "should be nil" do
        expect(@message_thread.scheduling_status).to equal(nil)
      end
    end

    context "messages_thread with free reply" do
      before do
        message = @message_thread.messages.create
        mc = message.message_classifications.create(@message_classification_params[:free_answer_1])
        mc.create_julie_action(@julie_action_params[:free_action_1])
      end
      it "should be nil" do
        expect(@message_thread.scheduling_status).to equal(nil)
      end
    end

    context "messages_thread with suggest availabilities" do
      before do
        message = @message_thread.messages.create
        mc = message.message_classifications.create(@message_classification_params[:ask_availabilities_1])
        mc.create_julie_action(@julie_action_params[:no_creation_1])
      end
      it "should be scheduling" do
        expect(@message_thread.scheduling_status).to equal(MessagesThread::SCHEDULING_EVENT)
      end
    end

    context "messages_thread with create events" do
      before do
        message = @message_thread.messages.create
        mc = message.message_classifications.create(@message_classification_params[:create_events_1])
        mc.create_julie_action(@julie_action_params[:no_creation_1])
      end
      it "should be events created" do
        expect(@message_thread.scheduling_status).to equal(MessagesThread::EVENTS_CREATED)
      end
    end

    context "messages_thread with event scheduled" do
      before do
        message = @message_thread.messages.create
        mc = message.message_classifications.create(@message_classification_params[:ask_availabilities_1])
        mc.create_julie_action(@julie_action_params[:creation_1])
      end
      it "should be event scheduled" do
        expect(@message_thread.scheduling_status).to equal(MessagesThread::EVENT_SCHEDULED)
      end
    end

    context "messages_thread with event unscheduled" do
      before do
        message_1 = @message_thread.messages.create
        mc_1 = message_1.message_classifications.create(@message_classification_params[:ask_availabilities_1])
        mc_1.create_julie_action(@julie_action_params[:creation_1])

        message_2 = @message_thread.messages.create
        mc_2 = message_1.message_classifications.create(@message_classification_params[:ask_availabilities_1])
        mc_2.create_julie_action(@julie_action_params[:deletion_1])
      end
      it "should be nil" do
        expect(@message_thread.scheduling_status).to equal(MessagesThread::SCHEDULING_EVENT )
      end
    end
  end
end