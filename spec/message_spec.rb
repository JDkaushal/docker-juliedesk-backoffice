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
end