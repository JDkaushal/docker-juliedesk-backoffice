require "rails_helper"

describe OperatorActionsGroup do

  before do

  end

  describe "group_actions" do
     context "complete action" do
        before do
          @messages_thread                = FactoryGirl.create(:messages_thread_with_messages)

          message_classification = @messages_thread.messages.first.message_classifications.first
          message_classification.classification = "suggest_dates"
          message_classification.save
          julie_action = message_classification.julie_action

          @open_messages_thread_oa_old    = FactoryGirl.create(:operator_action, operator_id: 7, messages_thread_id: @messages_thread.id, initiated_at: DateTime.parse("2015-05-01T12:00:00"), target_type: "MessagesThread", nature: "open")
          @open_messages_thread_oa        = FactoryGirl.create(:operator_action, operator_id: 7, messages_thread_id: @messages_thread.id, initiated_at: DateTime.parse("2015-05-01T12:00:02"), target_type: "MessagesThread", nature: "open")
          @lock_oa                        = FactoryGirl.create(:operator_action, operator_id: 7, messages_thread_id: @messages_thread.id, initiated_at: DateTime.parse("2015-05-01T12:00:08"), target_type: "MessagesThread", nature: "lock")
          @open_message_classification_oa = FactoryGirl.create(:operator_action, operator_id: 7, messages_thread_id: @messages_thread.id, initiated_at: DateTime.parse("2015-05-01T12:00:16"), target_type: "MessageClassification", target_id: message_classification.id, nature: "open")
          @open_julie_action_oa           = FactoryGirl.create(:operator_action, operator_id: 7, messages_thread_id: @messages_thread.id, initiated_at: DateTime.parse("2015-05-01T12:00:30"), target_type: "JulieAction", target_id: julie_action.id, nature: "open")
          @archive_messages_thread_oa     = FactoryGirl.create(:operator_action, operator_id: 7, messages_thread_id: @messages_thread.id, initiated_at: DateTime.parse("2015-05-01T12:00:40"), target_type: "MessagesThread", nature: "archive")
          @unlock_oa                      = FactoryGirl.create(:operator_action, operator_id: 7, messages_thread_id: @messages_thread.id, initiated_at: DateTime.parse("2015-05-01T12:00:55"), target_type: "MessagesThread", nature: "unlock")
        end
        it "Should group actions" do
          OperatorActionsGroup.group_actions({
              messages_thread_id: @messages_thread.id,
              operator_id: 7
                                             })

          operator_actions_group = OperatorActionsGroup.last
          expect(operator_actions_group).not_to be nil
          expect(operator_actions_group.label).to eq("suggest_dates")
          expect(operator_actions_group.operator_id).to eq(7)
          expect(operator_actions_group.messages_thread_id).to eq(@messages_thread.id)
          expect(operator_actions_group.initiated_at).to eq(DateTime.parse("2015-05-01T12:00:02"))
          expect(operator_actions_group.duration).to eq(38)

          expect(OperatorAction.find(@open_messages_thread_oa_old.id).operator_actions_group_id).to be nil
          expect(OperatorAction.find(@open_messages_thread_oa.id).operator_actions_group_id).to     eq(operator_actions_group.id)
          expect(OperatorAction.find(@lock_oa.id).operator_actions_group_id).to be nil
          expect(OperatorAction.find(@open_message_classification_oa.id).operator_actions_group_id).to eq(operator_actions_group.id)
          expect(OperatorAction.find(@open_julie_action_oa.id).operator_actions_group_id).to eq(operator_actions_group.id)
          expect(OperatorAction.find(@archive_messages_thread_oa.id).operator_actions_group_id).to eq(operator_actions_group.id)
          expect(OperatorAction.find(@unlock_oa.id).operator_actions_group_id).to be nil
        end

     end

     context "just archive action" do
       before do
         @messages_thread                = FactoryGirl.create(:messages_thread_with_messages)

         @open_messages_thread_oa_old    = FactoryGirl.create(:operator_action, operator_id: 7, messages_thread_id: @messages_thread.id, initiated_at: DateTime.parse("2015-05-01T12:00:00"), target_type: "MessagesThread", nature: "open")
         @open_messages_thread_oa_old_2  = FactoryGirl.create(:operator_action, operator_id: 7, messages_thread_id: @messages_thread.id, initiated_at: DateTime.parse("2015-05-01T12:00:01"), target_type: "MessagesThread", nature: "open")
         @open_messages_thread_oa        = FactoryGirl.create(:operator_action, operator_id: 7, messages_thread_id: @messages_thread.id, initiated_at: DateTime.parse("2015-05-01T12:00:02"), target_type: "MessagesThread", nature: "open")
         @lock_oa                        = FactoryGirl.create(:operator_action, operator_id: 7, messages_thread_id: @messages_thread.id, initiated_at: DateTime.parse("2015-05-01T12:00:08"), target_type: "MessagesThread", nature: "lock")
         @archive_messages_thread_oa     = FactoryGirl.create(:operator_action, operator_id: 7, messages_thread_id: @messages_thread.id, initiated_at: DateTime.parse("2015-05-01T12:00:40"), target_type: "MessagesThread", nature: "archive")
         @unlock_oa                      = FactoryGirl.create(:operator_action, operator_id: 7, messages_thread_id: @messages_thread.id, initiated_at: DateTime.parse("2015-05-01T12:00:55"), target_type: "MessagesThread", nature: "unlock")
       end
       it "Should group actions" do
         OperatorActionsGroup.group_actions({
                                                messages_thread_id: @messages_thread.id,
                                                operator_id: 7
                                            })

         operator_actions_group = OperatorActionsGroup.last
         expect(operator_actions_group).not_to be nil
         expect(operator_actions_group.label).to eq("archive")
         expect(operator_actions_group.operator_id).to eq(7)
         expect(operator_actions_group.messages_thread_id).to eq(@messages_thread.id)
         expect(operator_actions_group.initiated_at).to eq(DateTime.parse("2015-05-01T12:00:02"))
         expect(operator_actions_group.duration).to eq(38)

         expect(OperatorAction.find(@open_messages_thread_oa_old.id).operator_actions_group_id).to be nil
         expect(OperatorAction.find(@open_messages_thread_oa.id).operator_actions_group_id).to     eq(operator_actions_group.id)
         expect(OperatorAction.find(@lock_oa.id).operator_actions_group_id).to be nil
         expect(OperatorAction.find(@archive_messages_thread_oa.id).operator_actions_group_id).to eq(operator_actions_group.id)
         expect(OperatorAction.find(@unlock_oa.id).operator_actions_group_id).to be nil
       end

     end
  end

  describe "label_to_display" do
    context "label archive" do
      it "should return archive" do
        operator_actions_group = FactoryGirl.create(:operator_actions_group, label: OperatorActionsGroup::LABEL_ARCHIVE)
        expect(operator_actions_group.label_to_display).to eq("archive")
      end
    end
    context "label send_to_support" do
      context "no follow-up" do
        it "should return send_to_support" do
          operator_actions_group = FactoryGirl.create(:operator_actions_group, label: OperatorActionsGroup::LABEL_SEND_TO_SUPPORT)
          expect(operator_actions_group.label_to_display).to eq("send_to_support")
        end
      end
      context "follow-up" do
        it "should return follow up" do
          operator_actions_group = FactoryGirl.create(:operator_actions_group, label: OperatorActionsGroup::LABEL_SEND_TO_SUPPORT)
          FactoryGirl.create(:operator_action, operator_actions_group: operator_actions_group, message: "#FollowUp Hello")
          expect(operator_actions_group.label_to_display).to eq("Follow-up")
        end
      end
    end
  end

end