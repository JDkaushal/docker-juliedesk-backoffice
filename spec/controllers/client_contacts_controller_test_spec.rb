require_relative "../rails_helper"

describe ClientContactsController, :type => :controller do

  before(:each) do
    op = Operator.new(email: 'op@op', ips_whitelist_enabled: false)
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
      get :fetch, client_email: 'client@test.com', contacts_emails: [cc1.email, cc2.email]

      contacts = ClientContact.where(client_email: 'client@test.com', email: [cc1.email, cc2.email])
      expect(assigns(:contacts)).to eq(contacts)
    end

    it "should return the correct contacts infos" do

      cc1 = FactoryGirl.create(:client_contact)
      cc2 = FactoryGirl.create(:client_contact)

      allow(ClientContact).to receive(:fetch_redis).with(cc1.email).and_return({'email_aliases' => ['alias1@alias.com', 'alias2@alias.com'], 'full_name' => 'f n'})
      allow(ClientContact).to receive(:fetch_redis).with(cc2.email).and_return(nil)

      @request.env['HTTP_AUTHORIZATION'] = ActionController::HttpAuthentication::Basic.encode_credentials(@user,@pw)
      get :fetch, client_email: 'client@test.com', contacts_emails: [cc1.email, cc2.email]

      contacts = ClientContact.where(client_email: 'client@test.com', email: [cc1.email, cc2.email])
      expect(assigns(:contacts_infos)).to eq([{
                                                :id=>cc1.id,
                                                :client_email=>"client@test.com",
                                                :email=>cc1.email,
                                                :firstName=>'f',
                                                :lastName=>'n',
                                                :usageName=>nil,
                                                :gender=>nil,
                                                :isAssistant=>"false",
                                                :assisted=>"false",
                                                :assistedBy=>nil,
                                                :company=>"",
                                                :timezone=>nil,
                                                :landline=>nil,
                                                :mobile=>nil,
                                                :skypeId=>nil,
                                                :confCallInstructions=>nil,
                                                :isClient=>"true",
                                                :needAIConfirmation=>false
                                              },
                                              {
                                                :id=>cc2.id,
                                                :client_email=>"client@test.com",
                                                :email=>cc2.email,
                                                :firstName=>cc2.first_name,
                                                :lastName=>cc2.last_name,
                                                :usageName=>nil,
                                                :gender=>nil,
                                                :isAssistant=>"",
                                                :assisted=>"",
                                                :assistedBy=>nil,
                                                :company=>nil,
                                                :timezone=>nil,
                                                :landline=>nil,
                                                :mobile=>nil,
                                                :skypeId=>nil,
                                                :confCallInstructions=>nil,
                                                :isClient=>"false",
                                                :needAIConfirmation=>false}
                                             ])
    end

    it "should return the contacts infos if they are present in Database but not for the current user" do
      cc1 = FactoryGirl.create(:client_contact)
      cc2 = FactoryGirl.create(:client_contact)
      cc3 = FactoryGirl.create(:client_contact)
      cc4 = FactoryGirl.create(:client_contact)

      @request.env['HTTP_AUTHORIZATION'] = ActionController::HttpAuthentication::Basic.encode_credentials(@user,@pw)
      get :fetch, client_email: 'noContacts@test.com', contacts_emails: [cc1.email, cc2.email]

      expect(assigns(:contacts_infos)).to eq([{:email=>cc1.email, :firstName=>cc1.first_name, :lastName=>cc1.last_name, :gender=>cc1.gender}, {:email=>cc2.email, :firstName=>cc2.first_name, :lastName=>cc2.last_name, :gender=>cc2.gender}])
    end

    it "should set the correct email aliases array" do
      cc1 = FactoryGirl.create(:client_contact)
      cc2 = FactoryGirl.create(:client_contact)
      cc3 = FactoryGirl.create(:client_contact)

      allow(Account).to receive(:accounts_cache).and_return({cc1.email => {'email_aliases' => ['alias1@alias.com', 'alias2@alias.com'], 'full_name' => 'f n'}, cc2.email => {'email_aliases' => ['alias3@alias.com', 'alias4@alias.com'], 'full_name' => 'f n'}, 'aliasedMail@mail.com' => {'email_aliases' => [cc3.email, 'alias4@alias.com'], 'full_name' => 'f n'}})

      @request.env['HTTP_AUTHORIZATION'] = ActionController::HttpAuthentication::Basic.encode_credentials(@user,@pw)
      get :fetch, client_email: 'client@test.com', contacts_emails: [cc1.email, cc2.email, cc3.email]

      expect(assigns(:contacts_aliases)).to eq({"aliasedMail@mail.com" => [cc3.email, "alias4@alias.com"], cc1.email => ["alias1@alias.com", "alias2@alias.com"], cc2.email => ["alias3@alias.com", "alias4@alias.com"]})
    end

    it "should set the correct companies array" do
      cc1 = FactoryGirl.create(:client_contact)
      cc2 = FactoryGirl.create(:client_contact)
      cc3 = FactoryGirl.create(:client_contact)

      allow(Account).to receive(:accounts_cache).and_return({cc1.email => {'email_aliases' => ['alias1@alias.com', 'alias2@alias.com'], 'full_name' => 'f n', 'company_hash' => {'name' => 'Company 1'}}, cc2.email => {'email_aliases' => ['alias3@alias.com', 'alias4@alias.com'], 'full_name' => 'f n', 'company_hash' => {'name' => 'Company 2'}}, 'aliasedMail@mail.com' => {'email_aliases' => [cc3.email, 'alias4@alias.com'], 'full_name' => 'f n', 'company_hash' => {'name' => 'Company 3'}}})

      @request.env['HTTP_AUTHORIZATION'] = ActionController::HttpAuthentication::Basic.encode_credentials(@user,@pw)
      get :fetch, client_email: 'client@test.com', contacts_emails: [cc1.email, cc2.email, cc3.email]

      expect(assigns(:contacts_companies)).to eq({"aliasedMail@mail.com" => "Company 3", cc1.email => "Company 1", cc2.email => "Company 2"})
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

  describe "Get Emails Suggestions" do
    it 'should return an array of all the contacts emails in the database' do
      cc1 = FactoryGirl.create(:client_contact)
      cc2 = FactoryGirl.create(:client_contact)
      cc3 = FactoryGirl.create(:client_contact)
      cc4 = FactoryGirl.create(:client_contact)
      cc5 = FactoryGirl.create(:client_contact)
      cc6 = FactoryGirl.create(:client_contact)
      cc7 = ClientContact.create(client_email: 'teste@gregerg.com', email: 'llkiil@jjj.com')


      @request.env['HTTP_AUTHORIZATION'] = ActionController::HttpAuthentication::Basic.encode_credentials(@user,@pw)
      get :emails_suggestions, sub_string: 'pers'

      expect(assigns(:emails_suggestions)).to eq([cc1.email, cc2.email, cc3.email, cc4.email, cc5.email, cc6.email])

      get :emails_suggestions, sub_string: 'llk'

      expect(assigns(:emails_suggestions)).to eq([cc7.email])
    end
  end

  describe "Fetch One" do
    it 'should return the correct infos about a requested contact when it is not in its contacts network' do
      cc1 = FactoryGirl.create(:client_contact)

      @request.env['HTTP_AUTHORIZATION'] = ActionController::HttpAuthentication::Basic.encode_credentials(@user,@pw)
      response = get :fetch_one, client_email: 'fakeemail@mail.fr', email: cc1.email

      expect(JSON.parse(response.body)).to eq({"email"=>cc1.email, "firstName"=>cc1.first_name, "lastName"=>cc1.last_name, "gender"=>cc1.gender, "isClient"=>false})
    end

    it 'should return the correct infos about a requested contact when it is in its contacts network' do
      @request.env['HTTP_AUTHORIZATION'] = ActionController::HttpAuthentication::Basic.encode_credentials(@user,@pw)

      cc1 = ClientContact.create({
          client_email: 'client@mail.com',
          email: 'testlklklk@test.com',
          first_name: 'fname',
          last_name: 'lname',
          gender: 'M',
          usage_name: 'fname lname',
          is_assistant: true,
          assisted_by: "{\"email\":\"julie@juliedesk.com\",\"displayName\":\"Julie Desk\"}",
          timezone: "America/Chicago",
          landline: '0102030404',
          mobile: '0646646464',
          skypeId: 'Skype ID',
          conf_call_instructions: 'conf call'
          }
      )

      @request.env['HTTP_AUTHORIZATION'] = ActionController::HttpAuthentication::Basic.encode_credentials(@user,@pw)
      response = get :fetch_one, client_email: 'client@mail.com', email: cc1.email

      expect(JSON.parse(response.body)).to eq({"email"=>"testlklklk@test.com", "firstName"=>"fname", "lastName"=>"lname", "gender"=>"M", "usageName"=>"fname lname", "isAssistant"=>true, "assisted"=>nil, "assistedBy"=>"{\"email\":\"julie@juliedesk.com\",\"displayName\":\"Julie Desk\"}", "timezone"=>"America/Chicago", "landline"=>"0102030404", "mobile"=>"0646646464", "skypeId"=>"Skype ID", "confCallInstructions"=>"conf call", "isClient"=>false})
    end

    it 'should return the correct infos about a requested contact when it is in its contacts network and is a client (main email used)' do
      @request.env['HTTP_AUTHORIZATION'] = ActionController::HttpAuthentication::Basic.encode_credentials(@user,@pw)

      allow(Account).to receive(:accounts_cache).and_return({'test@test.com' => [present: true]})

      cc1 = ClientContact.create({
                                     client_email: 'client@mail.com',
                                     email: 'test@test.com',
                                     first_name: 'fname',
                                     last_name: 'lname',
                                     gender: 'M',
                                     usage_name: 'fname lname',
                                     is_assistant: true,
                                     assisted_by: "{\"email\":\"julie@juliedesk.com\",\"displayName\":\"Julie Desk\"}",
                                     timezone: "America/Chicago",
                                     landline: '0102030404',
                                     mobile: '0646646464',
                                     skypeId: 'Skype ID',
                                     conf_call_instructions: 'conf call'
                                 }
      )

      @request.env['HTTP_AUTHORIZATION'] = ActionController::HttpAuthentication::Basic.encode_credentials(@user,@pw)
      response = get :fetch_one, client_email: 'client@mail.com', email: cc1.email

      expect(JSON.parse(response.body)).to eq({"email"=>"test@test.com", "firstName"=>"fname", "lastName"=>"lname", "gender"=>"M", "usageName"=>"fname lname", "isAssistant"=>true, "assisted"=>nil, "assistedBy"=>"{\"email\":\"julie@juliedesk.com\",\"displayName\":\"Julie Desk\"}", "timezone"=>"America/Chicago", "landline"=>"0102030404", "mobile"=>"0646646464", "skypeId"=>"Skype ID", "confCallInstructions"=>"conf call", "isClient"=>true})
    end

    it 'should return the correct infos about a requested contact when it is in its contacts network and is a client (alias email used)' do
      @request.env['HTTP_AUTHORIZATION'] = ActionController::HttpAuthentication::Basic.encode_credentials(@user,@pw)

      allow(Account).to receive(:accounts_cache).and_return({'testalias@test.com' => {"email_aliases" => ['test@test.com']}})

      cc1 = ClientContact.create({
                                     client_email: 'client@mail.com',
                                     email: 'test@test.com',
                                     first_name: 'fname',
                                     last_name: 'lname',
                                     gender: 'M',
                                     usage_name: 'fname lname',
                                     is_assistant: true,
                                     assisted_by: "{\"email\":\"julie@juliedesk.com\",\"displayName\":\"Julie Desk\"}",
                                     timezone: "America/Chicago",
                                     landline: '0102030404',
                                     mobile: '0646646464',
                                     skypeId: 'Skype ID',
                                     conf_call_instructions: 'conf call'
                                 }
      )

      @request.env['HTTP_AUTHORIZATION'] = ActionController::HttpAuthentication::Basic.encode_credentials(@user,@pw)
      response = get :fetch_one, client_email: 'client@mail.com', email: cc1.email

      expect(JSON.parse(response.body)).to eq({"email"=>"test@test.com", "firstName"=>"fname", "lastName"=>"lname", "gender"=>"M", "usageName"=>"fname lname", "isAssistant"=>true, "assisted"=>nil, "assistedBy"=>"{\"email\":\"julie@juliedesk.com\",\"displayName\":\"Julie Desk\"}", "timezone"=>"America/Chicago", "landline"=>"0102030404", "mobile"=>"0646646464", "skypeId"=>"Skype ID", "confCallInstructions"=>"conf call", "isClient"=>true})
    end

    it 'should return an empty response' do
      cc1 = FactoryGirl.create(:client_contact)

      @request.env['HTTP_AUTHORIZATION'] = ActionController::HttpAuthentication::Basic.encode_credentials(@user,@pw)
      response = get :fetch_one, client_email: 'fakeemail@mail.fr', email: 'false@false.com'

      expect(JSON.parse(response.body)).to eq({"error"=>"Contact Not Found"})
    end
  end

  describe 'ai_get_company_name' do

    describe 'No association present in database' do
      it 'should make the call to the ai then save the result in database' do
        CompanyDomainAssociation.destroy_all

        @request.env['HTTP_AUTHORIZATION'] = ActionController::HttpAuthentication::Basic.encode_credentials(@user,@pw)

        expect_any_instance_of(AiProxy).to receive(:build_request).with(:get_company_name, { address: 'address@domain.com', message: 'fgtrgerferfer' }).and_return({'identification' => 'fullcontact', 'company' => 'company'})
        post :ai_get_company_name, {contact_address: 'address@domain.com', message_text: 'fgtrgerferfer'}

        last_assoc = CompanyDomainAssociation.last
        expect(last_assoc.domain).to eq('domain.com')
        expect(last_assoc.company_name).to eq('company')

      end
    end

    describe 'association present in database' do
      it 'should make the call to the ai then save the result in database' do
        CompanyDomainAssociation.create(domain: 'domain.com', company_name: 'company')

        @request.env['HTTP_AUTHORIZATION'] = ActionController::HttpAuthentication::Basic.encode_credentials(@user,@pw)

        expect_any_instance_of(AiProxy).not_to receive(:build_request)
        response = post :ai_get_company_name, {contact_address: 'address@domain.com', message_text: 'fgtrgerferfer'}

        expect(JSON.parse(response.body)).to eq({"identification"=>"backoffice_database", "company"=>"company"})
      end
    end


  end
end