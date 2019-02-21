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

      expect(response.status).to eq(302)
    end

    it 'should be accessible to authenticated operators' do

      expect(controller).to receive(:jd_auth_authenticate_server).and_return(true)
      expect(controller).to receive(:jd_auth_current_user).and_return(OpenStruct.new(email: @admin.email))

      post :change_sound

      expect(response.status).to eq(200)
    end
  end

  describe 'Actions' do

    before(:each) do
      expect(controller).to receive(:jd_auth_authenticate_server).at_least(:once).and_return(true)
      expect(controller).to receive(:jd_auth_current_user).at_least(:once).and_return(OpenStruct.new(email: @normal.email))
    end

    describe 'Change sound' do
      it 'should manage whether the sound is activated or not in the application' do
        post :change_sound, params: { activated: "false" }
        expect(session[:sound_is_activated]).to be(false)

        post :change_sound, params: { activated: "true" }
        expect(session[:sound_is_activated]).to be(true)
      end

      it 'should return the correct JSON' do
        post :change_sound, params: { activated: "false" }

        expect(response.body).to eq("{\"status\":\"success\",\"message\":\"\",\"data\":{}}")
      end
    end

    describe 'Locale Management' do
      controller do
        before_action :set_locale

        def index
          head :ok
        end
      end

      it 'should set the correct default locale if no locale is provided' do
        get :index

        expect(I18n.locale).to eq(:fr)
      end

      it 'should set the locale to en' do
        get :index, params: { locale: 'en' }

        expect(I18n.locale).to eq(:en)
      end

      it 'should fallback to fr when a not permitted locale is used' do
        get :index, params: { locale: 'de' }

        expect(I18n.locale).to eq(:fr)
      end
    end

    describe 'Admin reserved access' do


      context 'not admin' do
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
      end
    end
  end
end