require_relative "../rails_helper"

describe ReviewController, :type => :controller do

  controller do
    before_action :only_admin
    layout "review"

    def index
      render plain: 'OK'
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
      expect(controller).to receive(:jd_auth_authenticate_server).at_least(:once).and_return(true)
      expect(controller).to receive(:jd_auth_current_user).at_least(:once).and_return(OpenStruct.new(email: @user_non_admin))
      get :index

      expect(response).to redirect_to('/')
    end

    it 'should allow an admin to access it' do
      expect(controller).to receive(:jd_auth_authenticate_server).at_least(:once).and_return(true)
      expect(controller).to receive(:jd_auth_current_user).at_least(:once).and_return(OpenStruct.new(email: @user_admin))
      get :index

      expect(response.body).to eq('OK')
    end
  end

end