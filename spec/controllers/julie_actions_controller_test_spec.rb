require_relative "../rails_helper"

describe JulieActionsController, :type => :controller do

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
      @request.env['HTTP_AUTHORIZATION'] = ActionController::HttpAuthentication::Basic.encode_credentials(@user_non_admin,@pw)
    end

    describe 'Show' do

      it 'should get the correct JulieAction and populate the correct instance variables' do
        mc1 = FactoryGirl.create(:message_classification_complete)
        m1 = FactoryGirl.create(:message_complete)
        m2 = FactoryGirl.create(:message_complete)
        m3 = FactoryGirl.create(:message_complete)

        mc1.message = m1
        mc1.save

        mt1 = FactoryGirl.create(:messages_thread_for_inbox_count)
        mt1.messages << [m1, m2, m3]


        mt2 = FactoryGirl.create(:messages_thread_for_inbox_count)
        mt3 = FactoryGirl.create(:messages_thread_for_inbox_count)

        ja1 = JulieAction.create(message_classification_id: mc1.id)

        expect_any_instance_of(MessagesThread).to receive(:re_import).and_return(true)

        get :show, id: ja1.id

        expect(assigns(:julie_action)).to eq(ja1)
        expect(assigns(:message)).to eq(m1)

        expect(assigns(:messages_thread)).to eq(mt1)
        expect(assigns(:is_discussion_client_julie_only)).to be(false)
      end

      it 'should create the correct Operator Action' do

        mc1 = FactoryGirl.create(:message_classification_complete)
        m1 = FactoryGirl.create(:message_complete)
        m2 = FactoryGirl.create(:message_complete)
        m3 = FactoryGirl.create(:message_complete)

        mc1.message = m1
        mc1.save

        mt1 = FactoryGirl.create(:messages_thread_for_inbox_count)
        mt1.messages << [m1, m2, m3]


        mt2 = FactoryGirl.create(:messages_thread_for_inbox_count)
        mt3 = FactoryGirl.create(:messages_thread_for_inbox_count)

        ja1 = JulieAction.create(message_classification_id: mc1.id)

        expect_any_instance_of(MessagesThread).to receive(:re_import).and_return(true)
        allow(DateTime).to receive(:now).and_return(DateTime.new(2015, 10, 10))
        expect(OperatorAction).to receive(:create_and_verify).with({
                                                                       initiated_at: DateTime.new(2015, 10, 10),
                                                                       target: ja1,
                                                                       nature: OperatorAction::NATURE_OPEN,
                                                                       operator_id: @normal.id,
                                                                       messages_thread_id: mt1.id
                                                                   })

        get :show, id: ja1.id
      end
    end

    describe 'update' do

      it 'should render the correct JSON' do
        mc1 = FactoryGirl.create(:message_classification_complete)
        m1 = FactoryGirl.create(:message_complete)

        mc1.timezone = "Europe/Paris"
        mc1.message = m1
        mc1.save

        mt1 = FactoryGirl.create(:messages_thread_for_inbox_count)
        mt1.messages << m1

        ja1 = JulieAction.create(message_classification_id: mc1.id)


        put :update, id: ja1.id, text: 'New Text'

        expect(response.body).to eq("{\"status\":\"success\",\"message\":\"\",\"data\":{}}")
      end

      it 'should update correctly the julie action without call instructions' do
        mc1 = FactoryGirl.create(:message_classification_complete)
        m1 = FactoryGirl.create(:message_complete)

        mc1.timezone = "Europe/Paris"
        mc1.message = m1
        mc1.save

        mt1 = FactoryGirl.create(:messages_thread_for_inbox_count)
        mt1.messages << m1

        ja1 = JulieAction.create(message_classification_id: mc1.id)

        expect_any_instance_of(JulieAction).to receive(:update_attributes).with({
            text: 'New Text',
            generated_text: 'New Text generated',
            date_times: "[{\"timezone\":\"Europe/Paris\",\"date\":\"2015-11-27T14:00:01+00:00\"},{\"timezone\":\"Europe/Paris\",\"date\":\"2015-11-28T15:00:01+00:00\"},{\"timezone\":\"Europe/Paris\",\"date\":\"2015-11-29T14:20:01+00:00\"}]",
            event_id: "2",
            event_url: 'test@url.com',
            calendar_id: "2",
            calendar_login_username: 'username',
            done: true,
            events: "[{\"name\":\"event 1\"},{\"name\":\"event 2\"}]",
            processed_in: "3",
            deleted_event: false,
            :event_from_invitation=>nil,
            :event_from_invitation_organizer=>nil
        })
        put :update, id: ja1.id, text: 'New Text', generated_text: 'New Text generated', date_times: ["2015-11-27T15:00:01+01:00", "2015-11-28T16:00:01+01:00", "2015-11-29T15:20:01+01:00"], event_id: 2, event_url: 'test@url.com', calendar_id: 2, calendar_login_username: 'username', done: true, events: {1 => {name: 'event 1'}, 2 => {name: 'event 2'}}, processed_in: 3, deleted_event: false
      end

      it 'should update the calling instructions if present of the julie action message classification' do

        mc1 = FactoryGirl.create(:message_classification_complete)
        m1 = FactoryGirl.create(:message_complete)

        mc1.timezone = "Europe/Paris"
        mc1.message = m1
        mc1.save

        mt1 = FactoryGirl.create(:messages_thread_for_inbox_count)
        mt1.messages << m1

        ja1 = JulieAction.create(message_classification_id: mc1.id)

        expect_any_instance_of(MessageClassification).to receive(:update).with(call_instructions: "{\"target\":\"interlocutor\",\"targetInfos\":{\"$$hashKey\":\"object:162\",\"displayName\":\"Pierre Jean (grepolide@gmail.com)\",\"email\":\"grepolide@gmail.com\",\"guid\":\"174\",\"name\":\"Pierre Jean\"},\"support\":\"\",\"details\":\"\",\"event_instructions\":\"\"}", :virtual_resource_used=>nil)

        put :update, id: ja1.id, call_instructions: {target: "interlocutor", targetInfos: {'$$hashKey' => "object:162", displayName: "Pierre Jean (grepolide@gmail.com)", email: "grepolide@gmail.com", guid: 174 ,name: "Pierre Jean"}, support: "", details: "", event_instructions: ""}
      end

      it 'should update the messages_thread follow up date' do
        allow(Time).to receive(:now).and_return(DateTime.new(2016, 01, 01))

        mc1 = FactoryGirl.create(:message_classification_complete)
        m1 = FactoryGirl.create(:message_complete)

        mc1.timezone = "Europe/Paris"
        mc1.message = m1
        mc1.save

        mt1 = FactoryGirl.create(:messages_thread_for_inbox_count)
        mt1.messages << m1

        ja1 = JulieAction.create(message_classification_id: mc1.id, action_nature: JulieAction::JD_ACTION_SUGGEST_DATES)

        put :update, id: ja1.id, messages_thread_id: mt1.id, date_times: ["2016-01-10T15:00:01+01:00", "2016-01-12T16:00:01+01:00", "2016-01-29T15:20:01+01:00"], client_settings: {auto_follow_up: 'true'}

        mt1.reload
        expect(mt1.follow_up_reminder_date.to_s).to eq("2016-01-10 19:00:01 UTC")
      end

      it 'should update the messages_thread follow up date' do
        allow(Time).to receive(:now).and_return(DateTime.new(2016, 01, 01))

        mc1 = FactoryGirl.create(:message_classification_complete)
        m1 = FactoryGirl.create(:message_complete)

        mc1.timezone = "Europe/Paris"
        mc1.message = m1
        mc1.save

        mt1 = FactoryGirl.create(:messages_thread_for_inbox_count)
        mt1.messages << m1

        ja1 = JulieAction.create(message_classification_id: mc1.id, action_nature: JulieAction::JD_ACTION_SUGGEST_DATES)

        put :update, id: ja1.id, messages_thread_id: mt1.id, date_times: ["2016-01-10T15:00:01+01:00", "2016-01-12T16:00:01+01:00", "2016-01-29T15:20:01+01:00"], client_settings: {auto_follow_up: 'false'}

        mt1.reload
        expect(mt1.follow_up_reminder_date.to_s).to eq('')
      end

    end
  end
end