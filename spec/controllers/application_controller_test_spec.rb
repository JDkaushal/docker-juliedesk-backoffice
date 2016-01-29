require_relative "../rails_helper"

describe ApplicationController, :type => :controller do

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

  describe 'Access' do
    it 'should not be accessible to non-authenticated operators' do
      post :change_sound

      expect(response.status).to eq(401)
    end

    it 'should be accessible to authenticated operators' do
      @request.env['HTTP_AUTHORIZATION'] = ActionController::HttpAuthentication::Basic.encode_credentials(@user_non_admin,@pw)

      post :change_sound

      expect(response.status).to eq(200)
    end
  end

  describe 'Actions' do

    before(:each) do
      @request.env['HTTP_AUTHORIZATION'] = ActionController::HttpAuthentication::Basic.encode_credentials(@user_non_admin,@pw)
    end

    describe 'Change sound' do
      it 'should manage whether the sound is activated or not in the application' do
        post :change_sound, activated: "false"
        expect(session[:sound_is_activated]).to be(false)

        post :change_sound, activated: "true"
        expect(session[:sound_is_activated]).to be(true)
      end

      it 'should return the correct JSON' do
        post :change_sound, activated: "false"

        expect(response.body).to eq("{\"status\":\"success\",\"message\":\"\",\"data\":{}}")
      end
    end

    describe 'Locale Management' do
      controller do
        before_action :set_locale

        def index
          render nothing: true
        end
      end

      it 'should set the correct default locale if no locale is provided' do
        get :index

        expect(I18n.locale).to eq(:fr)
      end

      it 'should set the locale to en' do
        get :index, locale: 'en'

        expect(I18n.locale).to eq(:en)
      end

      it 'should fallback to fr when a not permitted locale is used' do
        get :index, locale: 'de'

        expect(I18n.locale).to eq(:fr)
      end
    end

    describe 'Admin reserved access' do
      controller do
        before_action :only_admin

        def index
          render nothing: true
        end
      end

      it 'should refuse the connection of non admin operators' do
        get :index

        expect(response).to redirect_to(root_path)
      end

      it 'should allow the connection of admin operators' do
        @request.env['HTTP_AUTHORIZATION'] = ActionController::HttpAuthentication::Basic.encode_credentials(@user_admin,@pw)

        get :index

        expect(response).not_to redirect_to(root_path)
        expect(response.status).to eq(200)
      end
    end

    describe 'Logout' do
      before(:each) do
        @op1 = FactoryGirl.create(:operator_actif)
        @op2 = FactoryGirl.create(:operator_actif)
      end

      it 'should unlock all the MessagesThreads locked by the currently logged operator' do
        mt1 = FactoryGirl.create(:messages_thread_for_inbox_count)
        mt2 = FactoryGirl.create(:messages_thread_for_inbox_count)
        mt3 = FactoryGirl.create(:messages_thread_for_inbox_count)
        mt4 = FactoryGirl.create(:messages_thread_for_inbox_count)
        mt5 = FactoryGirl.create(:messages_thread_for_inbox_count)
        mt6 = FactoryGirl.create(:messages_thread_for_inbox_count)

        [mt1, mt2, mt3].each{|mt| mt.update(locked_by_operator_id: @op1.id)}
        [mt4, mt5].each{|mt| mt.update(locked_by_operator_id: @op2.id)}
        @request.env['HTTP_AUTHORIZATION'] = ActionController::HttpAuthentication::Basic.encode_credentials(@op1.email,'password')

        get :logout

        mt1.reload
        mt2.reload
        mt3.reload
        mt4.reload
        mt5.reload
        mt6.reload

        expect([mt1.locked_by_operator_id, mt2.locked_by_operator_id, mt3.locked_by_operator_id]).to eq([nil, nil, nil])
        expect([mt4.locked_by_operator_id, mt5.locked_by_operator_id, mt6.locked_by_operator_id]).to eq([@op2.id, @op2.id, nil])
      end

      it 'should redirect to the correct url' do
        @request.env['HTTP_AUTHORIZATION'] = ActionController::HttpAuthentication::Basic.encode_credentials(@op1.email,'password')

        get :logout

        expect(response).to redirect_to("https://#{@op1.email}@juliedesk-backoffice.herokuapp.com")

      end
    end
  end
end