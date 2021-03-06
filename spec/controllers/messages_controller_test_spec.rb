require_relative "../rails_helper"

describe MessagesController, :type => :controller do

  before(:each) do
    @admin = Operator.new(email: 'admin@op.com', privilege: 'admin', active: true, ips_whitelist_enabled: false)
    @admin.password= 'op'
    @admin.save

    @normal = Operator.new(email: 'normal@op.com', active: true, name: 'normal op', ips_whitelist_enabled: false)
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
      expect(controller).to receive(:jd_auth_authenticate_server).at_least(:once).and_return(true)
      expect(controller).to receive(:jd_auth_current_user).at_least(:once).and_return(OpenStruct.new(email: @user_non_admin))
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
        post :classifying, params: { id: m1.id, classification: 'does not exist' }

        expect(assigns(:message)).to eq(m1)
        expect(assigns(:classification)).to eq('does not exist')
        expect(assigns(:messages_thread)).to eq(mt1)
      end

      def test_message_classification_creation(classification)
        mt1 = FactoryGirl.create(:messages_thread_for_inbox_count)
        m1 = FactoryGirl.create(:message_complete)

        mt1.messages << m1

        expect(MessageClassification).to receive(:create_from_params).with(classification: classification, operator: @user_non_admin, processed_in: 3600000).and_call_original

        post :classifying, params: { id: m1.id, classification: classification, started_at: DateTime.new(2015, 10, 10, 11, 00, 00).to_i * 1000 }

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

          expect_any_instance_of(MessagesThread).to receive(:send_to_admin).with(message: 'delegation message', operator: @normal.name)
          expect(OperatorAction).to receive(:create_and_verify).with({
                                                                         initiated_at: DateTime.new(2015, 10, 10, 12, 00, 00),
                                                                         target: mt1,
                                                                         nature: OperatorAction::NATURE_SEND_TO_SUPPORT,
                                                                         operator_id: @normal.id,
                                                                         messages_thread_id: m1.messages_thread_id,
                                                                         message: 'delegation message'
                                                                     })

          post :classifying, params: { id: m1.id, classification: MessageClassification::TO_FOUNDERS, to_admin_message: 'delegation message' }

          expect(response).to redirect_to(messages_threads_path)
        end
      end
      context 'Message Classification CANCEL_TO_FOUNDERS' do
        it 'should classify the message correctly' do
          mt1 = FactoryGirl.create(:messages_thread_for_inbox_count)
          m1 = FactoryGirl.create(:message_complete)

          mt1.messages << m1

          expect_any_instance_of(MessagesThread).to receive(:undelegate_to_admin)
          post :classifying, params: { id: m1.id, classification: MessageClassification::CANCEL_TO_FOUNDERS }

          expect(response).to redirect_to(messages_thread_path(mt1))
        end
      end

      context 'Message Classification CANCEL_TO_SUPPORT' do
        it 'should classify the message correctly' do
          mt1 = FactoryGirl.create(:messages_thread_for_inbox_count)
          m1 = FactoryGirl.create(:message_complete)

          mt1.messages << m1

          expect_any_instance_of(MessagesThread).to receive(:undelegate_to_support)
          post :classifying, params: { id: m1.id, classification: MessageClassification::CANCEL_TO_SUPPORT }

          expect(response).to redirect_to(messages_thread_path(mt1))
        end
      end
    end

    describe 'Classify' do
      before(:each) do
        allow(DateTime).to receive(:now).and_return(DateTime.new(2015, 10, 10, 12, 00, 00))

        allow_any_instance_of(JuliedeskTrackerInterface).to receive(:build_request)
      end

      it 'should populate the correct instance variables' do
        mt1 = FactoryGirl.create(:messages_thread_for_inbox_count)
        m1 = FactoryGirl.create(:message_complete)

        mt1.messages << m1

        expect(OperatorAction).to receive(:create_and_verify).and_return(true)

        expect(MessageClassification).to receive(:create_from_params).with({
                                                                               "classification"=>"ask_date_suggestions",
                                                                               "id"=>"#{m1.id}",
                                                                               "controller"=>"messages",
                                                                               "action"=>"classify",
                                                                               "operator"=>"normal@op.com",
                                                                               "messages_thread_id"=>mt1.id
                                                                           }).and_call_original

        post :classify, params: { id: m1.id, classification: MessageClassification::ASK_DATE_SUGGESTIONS }

        m1.reload
        expect(assigns(:message)).to eq(m1)
        expect(assigns(:message_classification)).to eq(m1.message_classifications.last)
      end

      it 'should create an new Operator Action' do
        mt1 = FactoryGirl.create(:messages_thread_for_inbox_count)
        m1 = FactoryGirl.create(:message_complete)

        mt1.messages << m1

        expect{
          # 300 000 ms == 5min
          post :classify, params: { id: m1.id, classification: MessageClassification::ASK_DATE_SUGGESTIONS, processed_in: 300000 }
        }.to change{OperatorAction.count}.by(1)

        expect(OperatorAction.last).to eq(m1.message_classifications.last.operator_actions.last)
      end

      it 'should make an http call when a GIVE_PREFERENCE classification is sent' do
        mt1 = FactoryGirl.create(:messages_thread_for_inbox_count)
        m1 = FactoryGirl.create(:message_complete)

        mt1.messages << m1

        expect(MessageClassification).to receive(:create_from_params).and_call_original

        expect(ADMIN_API_INTERFACE).to receive(:build_request).with(:set_awaiting_current_notes, {
          email: mt1.account_email,
          awaiting_current_notes: "Awaiting Current notes (review link: #{ENV['BACKOFFICE_BASE_URL']}/review/messages_threads/#{mt1.id}/review)"
        })

        # expect_any_instance_of(HTTP::Client).to receive(:post).with(URI.parse("https://test-app.herokuapp.com/api/v1/accounts/set_awaiting_current_notes"), json: {
        #                                                                                                                                                 email: mt1.account_email,
        #                                                                                                                                                 awaiting_current_notes: "Awaiting Current notes (review link: #{ENV['BACKOFFICE_BASE_URL']}/review/messages_threads/#{mt1.id}/review)"
        #                                                                                                                                             }, :ssl_context=>nil)
        # 300 000 ms == 5min
        post :classify, params: { id: m1.id, classification: MessageClassification::GIVE_PREFERENCE, processed_in: 300000, awaiting_current_notes: 'Awaiting Current notes' }
      end

      it 'should render the correct JSON' do
        mt1 = FactoryGirl.create(:messages_thread_for_inbox_count)
        m1 = FactoryGirl.create(:message_complete)

        mt1.messages << m1

        # 300 000 ms == 5min
        post :classify, params: { id: m1.id, classification: MessageClassification::ASK_DATE_SUGGESTIONS, processed_in: 300000, awaiting_current_notes: 'Awaiting Current notes' }

        m1.reload
        expect(response.body).to eq("{\"status\":\"success\",\"message\":\"\",\"redirect_url\":\"#{julie_action_path(m1.message_classifications.last.julie_action)}\",\"data\":{}}")
      end

      it 'should recompute the linked_attendees' do
        mt1 = FactoryGirl.create(:messages_thread_for_inbox_count)
        m1 = FactoryGirl.create(:message_complete)
        message_classif = FactoryGirl.create(:message_classification_complete)

        mt1.messages << m1

        expect_any_instance_of(MessagesThread).to receive(:has_clients_with_linked_attendees_enabled).and_return(true)
        expect_any_instance_of(MessagesThread).to receive(:compute_linked_attendees)

        allow(MessageClassification).to receive(:create_from_params).and_return(message_classif)
        allow(OperatorAction).to receive(:create_and_verify)
        allow_any_instance_of(MessageClassification).to receive(:classification)

        post :classify, params: { id: m1.id, classification: MessageClassification::ASK_DATE_SUGGESTIONS, processed_in: 300000, awaiting_current_notes: 'Awaiting Current notes', old_attendees: {'1' => {'isPresent' => 'true', 'email' => 'email@email.com'}}, attendees: {'1' => {'isPresent' => 'true', 'email' => 'email@email.com'}, '2' => {'isPresent' => 'true', 'email' => 'email2@email.com'}} }
      end


      it 'should not recompute the linked_attendees' do
        mt1 = FactoryGirl.create(:messages_thread_for_inbox_count)
        m1 = FactoryGirl.create(:message_complete)
        message_classif = FactoryGirl.create(:message_classification_complete)

        mt1.messages << m1

        expect_any_instance_of(MessagesThread).not_to receive(:compute_linked_attendees)

        allow(MessageClassification).to receive(:create_from_params).and_return(message_classif)
        allow(OperatorAction).to receive(:create_and_verify)
        allow_any_instance_of(MessageClassification).to receive(:classification)

        post :classify, params: { id: m1.id, classification: MessageClassification::ASK_DATE_SUGGESTIONS, processed_in: 300000, awaiting_current_notes: 'Awaiting Current notes', old_attendees: {}, attendees: {'0' => {'isPresent' => true, 'email' => 'email@email.com'}} }
      end
    end

    describe "generate_threads" do
      it 'should populate the correct instance variables' do
        mt1 = FactoryGirl.create(:messages_thread_for_inbox_count)
        m1 = FactoryGirl.create(:message_complete)

        mt1.messages << m1

        allow_any_instance_of(Message).to receive(:generate_threads).with([])
        post :generate_threads, params: { id: m1.id }

        expect(assigns(:message)).to eq(m1)
      end

      it 'should process the message correctly' do
        mt1 = FactoryGirl.create(:messages_thread_for_inbox_count)
        m1 = FactoryGirl.create(:message_complete)

        mt1.messages << m1

        expect_any_instance_of(Message).to receive(:generate_threads).with([{"arg1"=>"1", "arg2"=>"2"}])
        post :generate_threads, params: { id: m1.id, julie_messages: {0 => {'arg1' => 1, 'arg2' => 2}} }
      end

      it 'should render the correct JSON' do
        mt1 = FactoryGirl.create(:messages_thread_for_inbox_count)
        m1 = FactoryGirl.create(:message_complete)

        mt1.messages << m1

        allow_any_instance_of(Message).to receive(:generate_threads)

        post :generate_threads, params: { id: m1.id }

        expect(response.body).to eq("{\"status\":\"success\",\"message\":\"\",\"data\":{}}")
      end
    end

    describe "generate_threads_for_follow_up" do
      it 'should populate the correct instance variables' do
        mt1 = FactoryGirl.create(:messages_thread)
        m1 = FactoryGirl.create(:message, messages_thread: mt1)
        mt2 = FactoryGirl.create(:messages_thread)

        expect(GenerateFollowUpWorker).to receive(:enqueue).with("#{mt1.id}", "A relancer vite", @normal.id)

        post :generate_threads_for_follow_up, params: { id: m1.id, follow_up_data: {
                                                "0" => {
                                                    'messages_thread_id' => "#{mt1.id}",
                                                    'message' => "A relancer vite"
                                                }
                                            } }

        # expect(MessagesThread.find(mt1.id).should_follow_up).to eq(true)
        # expect(MessagesThread.find(mt1.id).follow_up_instruction).to eq("A relancer vite")
        #
        # expect(MessagesThread.find(mt2.id).should_follow_up).to eq(false)
        # expect(MessagesThread.find(mt2.id).follow_up_instruction).to eq(nil)
        #
        # operator_action_groups = MessagesThread.find(mt1.id).operator_actions_groups
        # expect(operator_action_groups.length).to eq(1)
        # expect(operator_action_groups.first.label).to eq(OperatorActionsGroup::LABEL_SEND_TO_SUPPORT)
        # expect(operator_action_groups.first.operator_actions.select{|oa| oa.nature == OperatorAction::NATURE_SEND_TO_SUPPORT}.first.try(:message)).to eq("#FollowUp A relancer vite")

        expect(JSON.parse(response.body)).to eq({
                                                    "status" => "success",
                                                    "data" => {}
                                                })
      end
    end

    describe 'Reply' do
      it 'should populate the correct instance variables' do
        mt1 = FactoryGirl.create(:messages_thread_for_inbox_count)
        mc1 = FactoryGirl.create(:message_classification_complete)
        m1 = FactoryGirl.create(:message_complete)

        mc1.timezone = "Europe/Paris"
        mc1.message = m1
        mc1.save

        ja1 = FactoryGirl.create(:julie_alias_random)
        jac1 = JulieAction.create(message_classification_id: mc1.id)

        mt1.messages << m1

        allow(EmailServer).to receive(:deliver_message).and_return({'id' => 2})

        post :reply, params: { id: m1.id, from: ja1.email, julie_action_id: jac1, text: 'blablabla' }

        expect(assigns(:message)).to eq(m1)
        expect(assigns(:julie_alias)).to eq (ja1)
        expect(assigns(:new_server_message_id)).to eq(2)
        expect(assigns(:julie_action)).to eq(jac1)
      end

      it 'should call the deliver_message method on the EmailServer with the correct params' do
        mt1 = FactoryGirl.create(:messages_thread_for_inbox_count)
        mc1 = FactoryGirl.create(:message_classification_complete)
        m1 = FactoryGirl.create(:message_complete)
        m1.update(server_message_id: 1)

        mc1.timezone = "Europe/Paris"
        mc1.message = m1
        mc1.save

        ja1 = FactoryGirl.create(:julie_alias_random)
        jac1 = JulieAction.create(message_classification_id: mc1.id)

        mt1.messages << m1

        expect(EmailServer).to receive(:deliver_message).with({
                                                                  from: "#{ja1.name} <#{ja1.email}>",
                                                                  to: "test@test.com",
                                                                  cc: "test2@test.com, test3@test.com, test4@test.com",
                                                                  text: "blablabla\nfezfzefzef\nferfzefezf\n\nferfreferSignature",
                                                                  html: "<div>blablabla</div>\n<div>fezfzefzef</div>\n<div>ferfzefezf</div>\n<div><br></div>\n<div>ferfrefer</div> <div>Signature</div>",
                                                                  quote_replied_message: false,
                                                                  quote_forward_message: false,
                                                                  reply_to_message_id: m1.server_message_id
                                                              }).and_return({'id' => 2})

        post :reply, params: { id: m1.id, from: ja1.email, julie_action_id: jac1, text: "blablabla\nfezfzefzef\nferfzefezf\n\nferfrefer", html_signature: "<div>Signature</div>", to: ['test@test.com'], cc: ['test2@test.com', 'test3@test.com', 'test4@test.com'] }
      end

      it 'should update the specified Julie Action with the new server message id' do
        mt1 = FactoryGirl.create(:messages_thread_for_inbox_count)
        mc1 = FactoryGirl.create(:message_classification_complete)
        m1 = FactoryGirl.create(:message_complete)

        mc1.timezone = "Europe/Paris"
        mc1.message = m1
        mc1.save

        ja1 = FactoryGirl.create(:julie_alias_random)
        jac1 = JulieAction.create(message_classification_id: mc1.id)

        mt1.messages << m1

        allow(EmailServer).to receive(:deliver_message).and_return({'id' => 2})
        expect_any_instance_of(JulieAction).to receive(:update_attribute).with(:server_message_id, 2)

        post :reply, params: { id: m1.id, from: ja1.email, julie_action_id: jac1, text: 'blablabla' }
      end

      it 'should render the correct JSON' do
        mt1 = FactoryGirl.create(:messages_thread_for_inbox_count)
        mc1 = FactoryGirl.create(:message_classification_complete)
        m1 = FactoryGirl.create(:message_complete)

        mc1.timezone = "Europe/Paris"
        mc1.message = m1
        mc1.save

        ja1 = FactoryGirl.create(:julie_alias_random)
        jac1 = JulieAction.create(message_classification_id: mc1.id)

        mt1.messages << m1

        allow(EmailServer).to receive(:deliver_message).and_return({'id' => 2})

        post :reply, params: { id: m1.id, from: ja1.email, julie_action_id: jac1, text: 'blablabla' }

        expect(response.body).to eq("{\"status\":\"success\",\"message\":\"\",\"data\":{}}")
      end
    end
  end

end