require_relative "../rails_helper"

describe ReviewController, :type => :controller do

  controller do
    before_filter :only_admin
    layout "review"

    def index
      render text: 'OK'
    end

    def new

    end
  end

  before(:each) do
    non_admin = Operator.new(email: 'nonAdmin@op.com', ips_whitelist_enabled: false)
    non_admin.password= 'op'
    non_admin.save

    admin = Operator.new(email: 'admin@op.com', privilege: 'admin', ips_whitelist_enabled: false)
    admin.password= 'op'
    admin.save

    @user_non_admin = non_admin.email
    @user_admin = admin.email
    @pw = 'op'
  end

  describe 'Inheritance' do
    it { expect(described_class).to be < ApplicationController }
  end

  describe 'Permissions' do

    it 'should not allow a non admin operator to access it' do
      @request.env['HTTP_AUTHORIZATION'] = ActionController::HttpAuthentication::Basic.encode_credentials(@user_non_admin,@pw)
      get :index

      expect(response).to redirect_to('/')
    end

    it 'should allow an admin to access it' do
      @request.env['HTTP_AUTHORIZATION'] = ActionController::HttpAuthentication::Basic.encode_credentials(@user_admin,@pw)
      get :index

      expect(response.body).to eq('OK')
    end
  end

  describe 'Layout' do
    it 'should render the correct layout' do
      expect(controller.send(:_layout)).to eq('review')
    end
  end
end