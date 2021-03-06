require_relative "../rails_helper"

describe JulieAliasesController, :type => :controller do

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

    describe 'Index' do

      it 'should populate the correct instance variables' do
        ja1 = FactoryGirl.create(:julie_alias_random)
        ja2 = FactoryGirl.create(:julie_alias_random)
        ja3 = FactoryGirl.create(:julie_alias_random)

        get :index
        expect(assigns(:julie_aliases)).to eq([ja1, ja2, ja3])
      end

      it 'should render the correct template' do
        get :index

        expect(response).to render_template(:index)
      end
    end

    describe 'Edit' do

      it 'should populate the correct instance variables' do
        ja1 = FactoryGirl.create(:julie_alias_random)

        get :edit, params: { id: ja1.id }
        expect(assigns(:julie_alias)).to eq(ja1)
      end

      it 'should render the correct template' do
        ja1 = FactoryGirl.create(:julie_alias_random)

        get :edit, params: { id: ja1.id }

        expect(response).to render_template(:edit)
      end
    end

    describe 'New' do

      it 'should create a new default Julie Alias' do

        expect(JulieAlias).to receive(:new).with(
          {
            name: "Julie Desk",
            footer_en: "\n\nBest regards,\n\nJulie\nArtificial Intelligence @",
            footer_fr: "\n\nCordialement,\n\nJulie\nIntelligence Artificielle @"
          }
        )

        get :new
      end

      it 'should render the correct template' do
        get :new

        expect(response).to render_template(:new)
      end
    end

    describe 'Update' do

      it 'should populate the correct instance variables' do
        ja1 = FactoryGirl.create(:julie_alias_random)

        put :update, params: { id: ja1.id, julie_alias: {name: 'new name'} }

        expect(assigns(:julie_alias)).to eq(ja1)
      end

      it 'should update the specified julie action with the provided parameters' do
        ja1 = FactoryGirl.create(:julie_alias_random)

        put :update, params: { id: ja1.id, julie_alias: {name: 'new name', email: 'new email', footer_en: 'footer enenenen', footer_fr: 'footer frfrf', signature_en: 'signature en', signature_fr: 'signature fr'} }

        ja1.reload
        expect([ja1.name, ja1.email, ja1.footer_en, ja1.footer_fr, ja1.signature_en, ja1.signature_fr]).to eq(['new name', 'new email', 'footer enenenen', 'footer frfrf', 'signature en', 'signature fr'])
      end

      it 'should redirect the user to the edit page' do
        ja1 = FactoryGirl.create(:julie_alias_random)

        put :update, params: { id: ja1.id, julie_alias: {name: 'new name', email: 'new email', footer_en: 'footer enenenen', footer_fr: 'footer frfrf', signature_en: 'signature en', signature_fr: 'signature fr'} }

        expect(response).to redirect_to(edit_julie_alias_path(ja1))
      end

    end

    describe 'create' do

      it 'should create a new Julie Alias' do
        expect{
          post :create, params: { julie_alias: {name: 'new name', email: 'new email', footer_en: 'footer enenenen', footer_fr: 'footer frfrf', signature_en: 'signature en', signature_fr: 'signature fr'} }
        }.to change{JulieAlias.count}.by(1)

        last_julie_alias = JulieAlias.last
        expect([last_julie_alias.name, last_julie_alias.email, last_julie_alias.footer_en, last_julie_alias.footer_fr, last_julie_alias.signature_en, last_julie_alias.signature_fr]).to eq(['new name', 'new email', 'footer enenenen', 'footer frfrf', 'signature en', 'signature fr'])
      end

      it 'should redirect the user to the index page' do
        post :create, params: { julie_alias: {name: 'new name', email: 'new email', footer_en: 'footer enenenen', footer_fr: 'footer frfrf', signature_en: 'signature en', signature_fr: 'signature fr'} }

        expect(response).to redirect_to(julie_aliases_path)
      end

    end

    describe 'Filtering Parameters' do
      controller do
        def test
          julie_alias_params
          head :ok
        end
      end

      it 'should permit the correct parameters' do
        routes.draw { post "test" => "julie_aliases#test"}

        expect_any_instance_of(ActionController::Parameters).to receive(:require).with(:julie_alias).and_return(ActionController::Parameters.new({name: 'new name', email: 'new email', footer_en: 'footer enenenen', footer_fr: 'footer frfrf', signature_en: 'signature en', signature_fr: 'signature fr'}))
        expect_any_instance_of(ActionController::Parameters).to receive(:permit).with(:name, :email, :footer_en, :footer_fr, :signature_en, :signature_fr).and_return(ActionController::Parameters.new({name: 'new name', email: 'new email', footer_en: 'footer enenenen', footer_fr: 'footer frfrf', signature_en: 'signature en', signature_fr: 'signature fr'}))

        post :test, params: { julie_alias: {name: 'new name', email: 'new email', footer_en: 'footer enenenen', footer_fr: 'footer frfrf', signature_en: 'signature en', signature_fr: 'signature fr'} }
      end
    end
  end
end