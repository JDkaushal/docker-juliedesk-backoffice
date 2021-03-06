require_relative "../rails_helper"

describe ApiController, :type => :controller do
  controller do
    before_action :authenticate, :cors_preflight_check
    after_action :cors_set_access_control_headers
    #skip_before_action :verify_authenticity_token

    def index
      render plain: 'Passed'
    end

    def options_request
      render nothing: true
    end
  end

  before(:each) do
    op = Operator.new(email: 'op@op')
    op.password= 'op'
    op.save

    @user = op.email
    @pw = 'op'
  end

  describe 'Inheritance' do
    it { expect(described_class).to be < ActionController::Base }
  end

  describe 'Authentication' do
    it 'should not authenticate correctly if the token is missing' do
      get :index
      expect(response.body).to eq '{"status":"error","message":"Authentication problem"}'
    end

    it 'should authenticate correctly if the token is set and valid' do
      request.headers['Authorization'] = ENV['API_KEY']
      get :index
      expect(response.body).to eq 'Passed'
    end
  end

  describe 'Request configuration' do

    it 'should set the correct headers in a before filter when an options request is handled' do
      routes.draw { match 'options_request' => 'api#options_request', via: [:options] }
      request.headers['Authorization'] = ENV['API_KEY']
      process :options_request, method: "OPTIONS"

      expect(response.headers.keys).to include(
         'Access-Control-Allow-Origin',
         'Access-Control-Allow-Methods',
         'Access-Control-Allow-Headers',
         'Access-Control-Max-Age',
       )
    end

    it 'should set the correct headers in an after filter when a request other than options is handled' do
      request.headers['Authorization'] = ENV['API_KEY']
      get :index

      expect(response.headers.keys).to include(
           'Access-Control-Allow-Origin',
           'Access-Control-Allow-Methods',
           'Access-Control-Allow-Headers',
           'Access-Control-Max-Age',
       )
    end
  end
end