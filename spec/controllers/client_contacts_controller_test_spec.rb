require_relative "../rails_helper"

describe ClientContactsController, :type => :controller do

  before(:each) do
    op = Operator.new(email: 'op@op')
    op.password= 'op'
    op.save

    @user = op.email
    @pw = 'op'
  end

  describe "Fetch" do
    it "should return the correct contacts" do

      cc1 = FactoryGirl.create(:client_contact)
      cc2 = FactoryGirl.create(:client_contact)

      @request.env['HTTP_AUTHORIZATION'] = ActionController::HttpAuthentication::Basic.encode_credentials(@user,@pw)
      puts @request.env['HTTP_AUTHORIZATION']
      get :fetch, client_email: 'client@test.com', contacts_emails: [cc1.email, cc2.email]

      contacts = ClientContact.where(client_email: 'client@test.com', email: [cc1.email, cc2.email])
      expect(assigns(:contacts)).to eq(contacts)
    end
  end

  describe "Synchronize" do
    it 'should create a new Contact' do
      expect{
        @request.env['HTTP_AUTHORIZATION'] = ActionController::HttpAuthentication::Basic.encode_credentials(@user,@pw)
        post :synchronize, client_email: 'client@test.com', contacts: [{email: 'ttest@test.com', firstName: 'fn'}].to_json
      }.to change(ClientContact, :count).by(1)
    end

    it 'should update an existing contact' do
      cc1 = FactoryGirl.create(:client_contact)
      expect{
        @request.env['HTTP_AUTHORIZATION'] = ActionController::HttpAuthentication::Basic.encode_credentials(@user,@pw)
        post :synchronize, client_email: 'client@test.com', contacts: [{email: cc1.email, firstName: 'newfn'}].to_json
      }.to_not change(ClientContact, :count)

      expect(ClientContact.last.first_name).to eq('newfn')
    end


  end



end