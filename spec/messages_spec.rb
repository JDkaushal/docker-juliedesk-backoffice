require "rails_helper"

describe Message do

  before do

  end

  describe "generator_mcs" do
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
        expect(@messages_thread.messages[0].generator_mcs).to eq([@messages_thread.messages[1].message_classifications.first])
      end
    end

    context "a julie_action has its google_message_id registered" do
      before do
        @messages_thread = FactoryGirl.create(:messages_thread_with_messages, messages_count: 3)

        message_2 = @messages_thread.messages[2]
        expect(message_2).to receive(:google_message).and_return({
                                                                   'message_id' => "G12457"
                                                               })
        message_1 = @messages_thread.messages[1]
        expect(message_1).to receive(:google_message).and_return({
                                                                     'message_id' => "G1"
                                                                 })

        message = @messages_thread.messages[0]
        expect(message).to receive(:google_message).exactly(2).times.and_return({
                                                                   'in_reply_to' => "G12457",
                                                                   'message_id' => "G0"

                                                               })
        message.google_message_id = "G12457"
        message.save
      end

      it "should return all the message_classification related to the messages replied by this one" do
        expect(@messages_thread.messages[0].generator_mcs).to eq([@messages_thread.messages[2].message_classifications.first])
      end
    end
  end
end