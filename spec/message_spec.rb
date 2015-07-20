require "rails_helper"

describe Message do

  before do

  end

  describe "generator_message_classification" do
    before do

    end

    context "a julie_action has its google_message_id registered" do
      before do
        @messages_thread = FactoryGirl.create(:messages_thread_with_messages, messages_count: 3)

        julie_action = @messages_thread.messages[1].message_classifications.first.julie_action
        julie_action.google_message_id = "G12457"
        julie_action.save

        message = @messages_thread.messages[0]
        message.google_message_id = "G12457"
        message.save
      end
      it "should return this julie action's message_classification" do
        expect(@messages_thread.messages[0].generator_message_classification).to eq(@messages_thread.messages[1].message_classifications.first)
      end
    end

    context "a julie_action has its google_message_id registered" do
      before do
        @messages_thread = FactoryGirl.create(:messages_thread_with_messages, messages_count: 3)
      end

      it "should return nil" do
        expect(@messages_thread.messages[0].generator_message_classification).to be nil
      end
    end
  end

  describe "initial_recipients" do
    context "Context 1" do
      before do
        messages_thread = FactoryGirl.create(:messages_thread)
        @message = FactoryGirl.create(
            :message,
            reply_all_recipients: {to: [{email: "elrandil1@gmail.com"}, {email: "nmarlier@gmail.com"}], cc: [{email: "elrandil2@gmail.com"}, {email: "nicolas.marlier@wanadoo.fr"}]}.to_json,
            messages_thread: messages_thread
        )
        expect(messages_thread).to receive(:contacts).with(with_client: true).and_return([])
        expect(messages_thread).to receive(:computed_data).and_return({
                                                                          attendees: [{'email' => "elrandil1@gmail.com"}]
                                                                      })
        expect(messages_thread).to receive_message_chain(:account, :all_emails).and_return(["nmarlier@gmail.com", "nicolas.marlier@wanadoo.fr"])
        allow(messages_thread).to receive(:client_email).and_return("nmarlier@gmail.com")
      end
      it "should return a hash with initial recipients" do
        expect(@message.initial_recipients).to eq({
                                                      to: ["elrandil1@gmail.com"].sort,
                                                      cc: ["nmarlier@gmail.com", "elrandil2@gmail.com"].sort,
                                                      client: "nmarlier@gmail.com",
                                                      possible: ["elrandil1@gmail.com", "elrandil2@gmail.com", "nmarlier@gmail.com"].sort

                                                  })
      end
    end

    context "Context 2" do
      before do
        messages_thread = FactoryGirl.create(:messages_thread)
        @message = FactoryGirl.create(
            :message,
            reply_all_recipients: {to: [{email: "elrandil1@gmail.com"}, {email: "nmarlier@gmail.com"}], cc: [{email: "elrandil2@gmail.com"}, {email: "nicolas.marlier@wanadoo.fr"}]}.to_json,
            messages_thread: messages_thread
        )
        expect(messages_thread).to receive(:contacts).with(with_client: true).and_return([])
        expect(messages_thread).to receive(:computed_data).and_return({
                                                                          attendees: []
                                                                      })
        expect(messages_thread).to receive_message_chain(:account, :all_emails).and_return(["nmarlier@gmail.com", "nicolas.marlier@wanadoo.fr"])
        allow(messages_thread).to receive(:client_email).and_return("nmarlier@gmail.com")
      end
      it "should return a hash with initial recipients" do
        expect(@message.initial_recipients).to eq({
                                                      to: ["nmarlier@gmail.com"].sort,
                                                      cc: ["elrandil1@gmail.com", "elrandil2@gmail.com"].sort,
                                                      client: "nmarlier@gmail.com",
                                                      possible: ["elrandil1@gmail.com", "elrandil2@gmail.com", "nmarlier@gmail.com"].sort

                                                  })
      end
    end

    context "Context 3" do
      before do
        messages_thread = FactoryGirl.create(:messages_thread)
        @message = FactoryGirl.create(
            :message,
            reply_all_recipients: {to: [{email: "nmarlier@gmail.com"}], cc: []}.to_json,
            messages_thread: messages_thread
        )
        expect(messages_thread).to receive(:contacts).with(with_client: true).and_return([])
        expect(messages_thread).to receive(:computed_data).and_return({
                                                                          attendees: [{'email' => "elrandil1@gmail.com"}, {'email' => "elrandil2@gmail.com"}]
                                                                      })
        expect(messages_thread).to receive_message_chain(:account, :all_emails).and_return(["nmarlier@gmail.com", "nicolas.marlier@wanadoo.fr"])
        allow(messages_thread).to receive(:client_email).and_return("nmarlier@gmail.com")
      end
      it "should return a hash with initial recipients" do
        expect(@message.initial_recipients).to eq({
                                                      to: ["elrandil1@gmail.com", "elrandil2@gmail.com"].sort,
                                                      cc: ["nmarlier@gmail.com"].sort,
                                                      client: "nmarlier@gmail.com",
                                                      possible: ["elrandil1@gmail.com", "elrandil2@gmail.com", "nmarlier@gmail.com"].sort

                                                  })
      end
    end

    context "No client email in dest" do
      before do
        messages_thread = FactoryGirl.create(:messages_thread)
        @message = FactoryGirl.create(
            :message,
            reply_all_recipients: {to: [{email: "elrandil1@gmail.com"}], cc: [{email: "elrandil2@gmail.com"}]}.to_json,
            messages_thread: messages_thread
        )
        expect(messages_thread).to receive(:contacts).with(with_client: true).and_return([])
        expect(messages_thread).to receive(:computed_data).and_return({
                                                                          attendees: [{'email' => "elrandil1@gmail.com"}, {'email' => "elrandil2@gmail.com"}]
                                                                      })
        expect(messages_thread).to receive_message_chain(:account, :all_emails).and_return(["nmarlier@gmail.com", "nicolas.marlier@wanadoo.fr"])
        allow(messages_thread).to receive(:client_email).and_return("nmarlier@gmail.com")
      end
      it "should return a hash with initial recipients" do
        expect(@message.initial_recipients).to eq({
                                                      to: ["elrandil1@gmail.com", "elrandil2@gmail.com"].sort,
                                                      cc: ["nmarlier@gmail.com"].sort,
                                                      client: "nmarlier@gmail.com",
                                                      possible: ["elrandil1@gmail.com", "elrandil2@gmail.com", "nmarlier@gmail.com"].sort

                                                  })
      end
    end

    context "Only client" do
      before do
        messages_thread = FactoryGirl.create(:messages_thread)
        @message = FactoryGirl.create(
            :message,
            reply_all_recipients: {to: [{email: "nmarlier@gmail.com"}], cc: []}.to_json,
            messages_thread: messages_thread
        )
        expect(messages_thread).to receive(:contacts).with(with_client: true).and_return([])
        expect(messages_thread).to receive(:computed_data).and_return({
                                                                          attendees: []
                                                                      })
        expect(messages_thread).to receive_message_chain(:account, :all_emails).and_return(["nmarlier@gmail.com", "nicolas.marlier@wanadoo.fr"])
        allow(messages_thread).to receive(:client_email).and_return("nmarlier@gmail.com")
      end
      it "should return a hash with initial recipients" do
        expect(@message.initial_recipients).to eq({
                                                      to: ["nmarlier@gmail.com"].sort,
                                                      cc: [].sort,
                                                      client: "nmarlier@gmail.com",
                                                      possible: ["nmarlier@gmail.com"].sort

                                                  })
      end
    end

  end
end