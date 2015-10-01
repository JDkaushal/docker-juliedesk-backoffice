require "rails_helper"

describe OperatorAction do

  before do
    @open_messages_thread_oa        = FactoryGirl.create(:operator_action, target_type: "MessagesThread", nature: "open")
    @lock_oa                        = FactoryGirl.create(:operator_action, target_type: "MessagesThread", nature: "lock")
    @open_message_classification_oa = FactoryGirl.create(:operator_action, target_type: "MessageClassification", nature: "open")
    @open_julie_action_oa           = FactoryGirl.create(:operator_action, target_type: "JulieAction", nature: "open")
    @archive_messages_thread_oa     = FactoryGirl.create(:operator_action, target_type: "MessagesThread", nature: "archive")
    @unlock_oa                      = FactoryGirl.create(:operator_action, target_type: "MessagesThread", nature: "unlock")
  end

  describe "real_action?" do

    it "should returns false for lock and unlock, true otherwise" do
      expect(@open_messages_thread_oa.real_action?).to        be true
      expect(@lock_oa.real_action?).to                        be false
      expect(@open_message_classification_oa.real_action?).to be true
      expect(@open_julie_action_oa.real_action?).to           be true
      expect(@archive_messages_thread_oa.real_action?).to     be true
      expect(@unlock_oa.real_action?).to                      be false
    end

  end

  describe "target_using_cache" do
    context "for open julie_action" do
      before do
        messages_thread = FactoryGirl.create(:messages_thread_with_messages)
        @open_julie_action_oa.messages_thread = messages_thread
        @julie_action = messages_thread.messages.first.message_classifications.first.julie_action
        @open_julie_action_oa.target_id = @julie_action.id
        @open_julie_action_oa.target_type = @julie_action.class.to_s
      end
      it "should returns target by accessing the messages_thread object" do
        expect(@open_julie_action_oa).not_to receive(:target)
        expect(@open_julie_action_oa.target_using_cache).to eq(@julie_action)
      end
    end

    context "for open messages_classication" do
      before do
        messages_thread = FactoryGirl.create(:messages_thread_with_messages)
        @open_julie_action_oa.messages_thread = messages_thread
        @message_classification = messages_thread.messages.first.message_classifications.first
        @open_julie_action_oa.target_id = @message_classification.id
        @open_julie_action_oa.target_type = @message_classification.class.to_s
      end
      it "should returns target by accessing the messages_thread object" do
        expect(@open_julie_action_oa).not_to receive(:target)
        expect(@open_julie_action_oa.target_using_cache).to eq(@message_classification)
      end
    end

    context "otherwise" do
      before do
        @messages_thread = FactoryGirl.create(:messages_thread_with_messages)
        @open_messages_thread_oa.target     = @messages_thread
        @lock_oa.target                     = @messages_thread
        @archive_messages_thread_oa.target  = @messages_thread
        @unlock_oa.target                   = @messages_thread
      end
      it "should returns target" do
        expect(@open_messages_thread_oa.target).to    eq(@messages_thread)
        expect(@lock_oa.target).to                    eq(@messages_thread)
        expect(@archive_messages_thread_oa.target).to eq(@messages_thread)
        expect(@unlock_oa.target).to                  eq(@messages_thread)
      end
    end
  end

  describe "is_open_thread?" do
    it "should returns true for open thread, false otherwise" do
      expect(@open_messages_thread_oa.is_open_thread?).to        be true
      expect(@lock_oa.is_open_thread?).to                        be false
      expect(@open_message_classification_oa.is_open_thread?).to be false
      expect(@open_julie_action_oa.is_open_thread?).to           be false
      expect(@archive_messages_thread_oa.is_open_thread?).to     be false
      expect(@unlock_oa.is_open_thread?).to                      be false
    end
  end

  describe "is_archive_thread?" do
    it "should returns true for archive thread, false otherwise" do
      expect(@open_messages_thread_oa.is_archive_thread?).to        be false
      expect(@lock_oa.is_archive_thread?).to                        be false
      expect(@open_message_classification_oa.is_archive_thread?).to be false
      expect(@open_julie_action_oa.is_archive_thread?).to           be false
      expect(@archive_messages_thread_oa.is_archive_thread?).to     be true
      expect(@unlock_oa.is_archive_thread?).to                      be false
    end
  end

  describe "is_open_julie_action?" do
    it "should returns true for julie action, false otherwise" do
      expect(@open_messages_thread_oa.is_open_julie_action?).to        be false
      expect(@lock_oa.is_open_julie_action?).to                        be false
      expect(@open_message_classification_oa.is_open_julie_action?).to be false
      expect(@open_julie_action_oa.is_open_julie_action?).to           be true
      expect(@archive_messages_thread_oa.is_open_julie_action?).to     be false
      expect(@unlock_oa.is_open_julie_action?).to                      be false
    end
  end

  describe "is_open_message_classification?" do
    it "should returns true for open message classification, false otherwise" do
      expect(@open_messages_thread_oa.is_open_message_classification?).to        be false
      expect(@lock_oa.is_open_message_classification?).to                        be false
      expect(@open_message_classification_oa.is_open_message_classification?).to be true
      expect(@open_julie_action_oa.is_open_message_classification?).to           be false
      expect(@archive_messages_thread_oa.is_open_message_classification?).to     be false
      expect(@unlock_oa.is_open_message_classification?).to                      be false
    end
  end

  describe "is_grouped?" do
    before do
      @open_messages_thread_oa.operator_actions_group_id = 1
    end
    it "should returns if operator_actions_group is defined, false otherwise" do
      expect(@open_messages_thread_oa.is_grouped?).to        be true
      expect(@lock_oa.is_grouped?).to                        be false
      expect(@open_message_classification_oa.is_grouped?).to be false
      expect(@open_julie_action_oa.is_grouped?).to           be false
      expect(@archive_messages_thread_oa.is_grouped?).to     be false
      expect(@unlock_oa.is_grouped?).to                      be false
    end
  end

  describe "create_and_verify" do
    context "target is not specified" do
      it "should raise" do
        expect{OperatorAction.create_and_verify({})}.to raise_error("No target specified")
      end
    end

    context "target is specified, is not an archive" do
      before do
        messages_thread = FactoryGirl.create(:messages_thread_with_messages)
        @julie_action = messages_thread.messages.first.message_classifications.first.julie_action
      end
      it "should creates an object and runs the group action if needed" do
        expect(@julie_action).to receive_message_chain(:operator_actions, :create).with({
                                                                                              initiated_at: DateTime.parse("1989-05-03"),
                                                                                              messages_thread_id: 1,
                                                                                              operator_id: 2,
                                                                                              nature: "nature",
                                                                                              sub_nature: nil,
                                                                                              message: nil
                                                                                          })
        expect(OperatorActionsGroup).not_to receive(:group_actions)
        OperatorAction.create_and_verify({
            target: @julie_action,
            initiated_at: DateTime.parse("1989-05-03"),
            messages_thread_id: 1,
            operator_id: 2,
            nature: "nature"
                                                })
      end
    end

    context "target is specified, is an archive" do
      before do
        @messages_thread = FactoryGirl.create(:messages_thread_with_messages)
      end
      it "should creates an object and runs the group action if needed" do
        expect(@messages_thread).to receive_message_chain(:operator_actions, :create).with({
                                                                                              initiated_at: DateTime.parse("1989-05-03"),
                                                                                              messages_thread_id: 1,
                                                                                              operator_id: 2,
                                                                                              nature: "archive",
                                                                                              sub_nature: nil,
                                                                                              message: nil
                                                                                          })
        expect(OperatorActionsGroup).to receive(:group_actions).with({
            operator_id: 2,
            messages_thread_id: 1
                                                                     })
        OperatorAction.create_and_verify({
                                             target: @messages_thread,
                                             initiated_at: DateTime.parse("1989-05-03"),
                                             messages_thread_id: 1,
                                             operator_id: 2,
                                             nature: "archive"
                                         })
      end
    end

  end
end