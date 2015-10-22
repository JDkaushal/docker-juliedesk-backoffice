require_relative "../rails_helper"

describe MessagesController, :type => :controller do

  before(:each) do
    @admin = Operator.new(email: 'admin@op.com', privilege: 'admin', active: true)
    @admin.password= 'op'
    @admin.save

    @normal = Operator.new(email: 'normal@op.com', active: true, name: 'normal op')
    @normal.password= 'op'
    @normal.save

    @user_non_admin = @normal.email
    @user_admin = @admin.email
    @pw = 'op'
  end

  describe 'Inheritance' do
    it { expect(described_class).to be < ApplicationController }
  end

  describe 'Actions' do

    before(:each) do
      @request.env['HTTP_AUTHORIZATION'] = ActionController::HttpAuthentication::Basic.encode_credentials(@user_non_admin,@pw)
    end

    describe 'Classifying' do
      before(:each) do
        allow(DateTime).to receive(:now).and_return(DateTime.new(2015, 10, 10, 12, 00, 00))
      end

      it 'should populate the correct instance variables' do
        mt1 = FactoryGirl.create(:messages_thread_for_inbox_count)
        m1 = FactoryGirl.create(:message_complete)

        mt1.messages << m1

        expect_any_instance_of(MessagesThread).to receive(:re_import).and_return(true)
        post :classifying, id: m1.id, classification: 'does not exist'

        expect(assigns(:message)).to eq(m1)
        expect(assigns(:classification)).to eq('does not exist')
        expect(assigns(:messages_thread)).to eq(mt1)
      end

      def test_message_classification_creation(classification)
        mt1 = FactoryGirl.create(:messages_thread_for_inbox_count)
        m1 = FactoryGirl.create(:message_complete)

        mt1.messages << m1

        expect(MessageClassification).to receive(:create_from_params).with(classification: classification, operator: @user_non_admin, processed_in: 3600000).and_call_original

        post :classifying, id: m1.id, classification: classification, started_at: DateTime.new(2015, 10, 10, 11, 00, 00).to_i * 1000

        m1.reload
        expect(response).to redirect_to(julie_action_path(m1.message_classifications.last.julie_action))
      end

      context 'Message Classification UNKNOWN' do
        it 'should create the correct message classification for the specified message' do
          test_message_classification_creation(MessageClassification::UNKNOWN)
        end
      end
      context 'Message Classification ASK_INFO' do
        it 'should create the correct message classification for the specified message' do
          test_message_classification_creation(MessageClassification::ASK_INFO)
        end
      end
      context 'Message Classification ASK_CREATE_EVENT' do
        it 'should create the correct message classification for the specified message' do
          test_message_classification_creation(MessageClassification::ASK_CREATE_EVENT)
        end
      end
      context 'Message Classification TO_FOUNDERS' do
        it 'should classify the message correctly' do
          mt1 = FactoryGirl.create(:messages_thread_for_inbox_count)
          m1 = FactoryGirl.create(:message_complete)

          mt1.messages << m1

          expect_any_instance_of(MessagesThread).to receive(:delegate_to_support).with(message: 'delegation message', operator: @normal.name)
          expect(OperatorAction).to receive(:create_and_verify).with({
               initiated_at: DateTime.new(2015, 10, 10, 12, 00, 00),
               target: mt1,
               nature: OperatorAction::NATURE_SEND_TO_SUPPORT,
               operator_id: @normal.id,
               messages_thread_id: m1.messages_thread_id,
               message: 'delegation message'
           })

          post :classifying, id: m1.id, classification: MessageClassification::TO_FOUNDERS, to_founders_message: 'delegation message'

          expect(response).to redirect_to(messages_threads_path)
        end
      end
      context 'Message Classification CANCEL_TO_FOUNDERS' do
        it 'should classify the message correctly' do
          mt1 = FactoryGirl.create(:messages_thread_for_inbox_count)
          m1 = FactoryGirl.create(:message_complete)

          mt1.messages << m1

          expect_any_instance_of(MessagesThread).to receive(:undelegate_to_support)
          post :classifying, id: m1.id, classification: MessageClassification::CANCEL_TO_FOUNDERS

          expect(response).to redirect_to(messages_thread_path(mt1))
        end
      end
      context 'Message Classification ASSOCIATE_EVENT' do
        it 'should classify the message correctly' do
          mt1 = FactoryGirl.create(:messages_thread_for_inbox_count)
          m1 = FactoryGirl.create(:message_complete)

          mt1.messages << m1

          expect_any_instance_of(MessagesThread).to receive(:re_import).and_return(true)
          post :classifying, id: m1.id, classification: MessageClassification::ASSOCIATE_EVENT

          expect(response).to render_template(:classifying_admin)
        end
      end
    end

    # describe 'Wait For Preference Change' do
    #   mt1 = FactoryGirl.create(:messages_thread_for_inbox_count)
    #   m1 = FactoryGirl.create(:message_complete)
    #
    #   mt1.messages << m1
    #
    #   expect_any_instance_of(MessagesThread).to receive(:delegate_to_support).with('')
    #   expect()
    #
    #
    # end
  end

end