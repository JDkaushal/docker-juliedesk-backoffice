require_relative "../../rails_helper"

describe Review::OperatorsPresenceController, :type => :controller do

  before(:each) do
    @admin = Operator.new(email: 'admin@op.com', privilege: 'admin', active: true, ips_whitelist_enabled: false, planning_access: true)
    @admin.password= 'op'
    @admin.save

    @normal = Operator.new(email: 'normal@op.com', active: true, name: 'normal op', ips_whitelist_enabled: false, planning_access: false)
    @normal.password= 'op'
    @normal.save

    @user_non_admin = @normal.email
    @user_admin = @admin.email
    @pw = 'op'
  end

  describe 'Inheritance' do
    it { expect(described_class).to be < ReviewController }
  end

  describe 'Actions' do

    before(:each) do
      expect(controller).to receive(:jd_auth_authenticate_server).at_least(:once).and_return(true)

      @op1 = FactoryGirl.create(:operator_actif)
      @op2 = FactoryGirl.create(:operator_actif)
      @op3 = FactoryGirl.create(:operator_actif)
      @op4 = FactoryGirl.create(:operator_actif)
      @op5 = FactoryGirl.create(:operator_actif)

    end

    describe 'Index' do
      render_views

      it 'should access the index page if the operator has admin privileges' do
        expect(controller).to receive(:jd_auth_current_user).at_least(:once).and_return(OpenStruct.new(email: @user_admin))
        get :index
        expect(response).to render_template(:index)
      end


      it 'should not access the index page if the operator has not admin privileges' do
        expect(controller).to receive(:jd_auth_current_user).at_least(:once).and_return(OpenStruct.new(email: @user_non_admin))
        get :index
        expect(response).to redirect_to(root_path)
      end



      it 'should populate the correct instance variables' do
        expect(controller).to receive(:jd_auth_current_user).at_least(:once).and_return(OpenStruct.new(email: @user_admin))
        get :index, params: { start: Time.now }

        expect(assigns(:operators).map(&:id)).to eq([@normal.id, @op1.id, @op2.id, @op3.id, @op4.id, @op5.id])
      end

      it 'should return the correct html if a start parameter is provided' do
        @op1.operator_presences.create(date: DateTime.new(2015, 9, 10, 10, 00, 00))
        @op1.operator_presences.create(date: DateTime.new(2015, 9, 10, 10, 30, 00))
        @op1.operator_presences.create(date: DateTime.new(2015, 9, 11, 12, 00, 00))
        @op2.operator_presences.create(date: DateTime.new(2015, 9, 11, 12, 00, 00))

        @op3.privilege = Operator::PRIVILEGE_SUPER_OPERATOR_LEVEL_1
        @op3.save
        @op4.privilege = Operator::PRIVILEGE_SUPER_OPERATOR_LEVEL_2
        @op4.save


        expect(controller).to receive(:jd_auth_current_user).at_least(:once).and_return(OpenStruct.new(email: @user_admin))

        get :index, params: { start: DateTime.new(2015, 9, 10) }
        expect(response.body).to eq(<<END
Semaine 36;Thursday;Friday;Saturday;Sunday;Monday;Tuesday;Wednesday;Count
#{@normal.name};;;;;;;;0.0
#{@op1.name};13h00 - 14h00;15h00 - 15h30;;;;;;1.5
#{@op2.name};;15h00 - 15h30;;;;;;0.5
#{@op5.name};;;;;;;;0.0
* #{@op3.name};;;;;;;;0.0
** #{@op4.name};;;;;;;;0.0
;
;
Semaine 36;Thursday;;;Friday;;;Saturday;;;Sunday;;;Monday;;;Tuesday;;;Wednesday;;;Total
#{@normal.name};0.0;0.0;0.0;0.0;0.0;0.0;0.0;0.0;0.0;0.0;0.0;0.0;0.0;0.0;0.0;0.0;0.0;0.0;0.0;0.0;0.0;0.0
#{@op1.name};1.0;0.0;1.0;0.5;0.0;0.5;0.0;0.0;0.0;0.0;0.0;0.0;0.0;0.0;0.0;0.0;0.0;0.0;0.0;0.0;0.0;1.5
#{@op2.name};0.0;0.0;0.0;0.5;0.0;0.5;0.0;0.0;0.0;0.0;0.0;0.0;0.0;0.0;0.0;0.0;0.0;0.0;0.0;0.0;0.0;0.5
#{@op5.name};0.0;0.0;0.0;0.0;0.0;0.0;0.0;0.0;0.0;0.0;0.0;0.0;0.0;0.0;0.0;0.0;0.0;0.0;0.0;0.0;0.0;0.0
* #{@op3.name};0.0;0.0;0.0;0.0;0.0;0.0;0.0;0.0;0.0;0.0;0.0;0.0;0.0;0.0;0.0;0.0;0.0;0.0;0.0;0.0;0.0;0.0
** #{@op4.name};0.0;0.0;0.0;0.0;0.0;0.0;0.0;0.0;0.0;0.0;0.0;0.0;0.0;0.0;0.0;0.0;0.0;0.0;0.0;0.0;0.0;0.0
END
)
      end

      it 'should render the correct json' do
        @op1.operator_presences.create(date: DateTime.new(2015, 9, 10, 10, 00, 00))
        @op1.operator_presences.create(date: DateTime.new(2015, 9, 11, 12, 00, 00))
        @op2.operator_presences.create(date: DateTime.new(2015, 9, 11, 12, 00, 00))
        @op2.operator_presences.create(date: DateTime.new(2015, 9, 11, 13, 00, 00), is_review: true)

        @op3.privilege = Operator::PRIVILEGE_SUPER_OPERATOR_LEVEL_1
        @op3.save
        @op4.privilege = Operator::PRIVILEGE_SUPER_OPERATOR_LEVEL_2
        @op4.save

        expect(controller).to receive(:jd_auth_current_user).at_least(:once).and_return(OpenStruct.new(email: @user_admin))

        get :index, params: { start: DateTime.new(2015, 9, 10).to_s, format: :json }

        body = JSON.parse response.body
        expect(body['status']).to eq("success")
        expect(body['data']).to eq({
                                       "operators" => [
                                           {"name" => @normal.name, "id" => @normal.id, "stars" => nil,   "privilege" => nil, "in_formation"=>false, "color"=>"#ffffff", "presences" => [], "review_presences" => []},
                                           {"name" => @op1.name,    "id" => @op1.id,    "stars" => nil,   "privilege" => nil, "in_formation"=>false, "color"=>"#ffffff", "presences" => ["20150910T100000", "20150911T120000"], "review_presences" => []},
                                           {"name" => @op2.name,    "id" => @op2.id,    "stars" => nil,   "privilege" => nil, "in_formation"=>false, "color"=>"#ffffff", "presences" => ["20150911T120000"], "review_presences" => ["20150911T130000"]},
                                           {"name" => @op5.name,    "id" => @op5.id,    "stars" => nil,   "privilege" => nil, "in_formation"=>false, "color"=>"#ffffff", "presences" => [], "review_presences" => []},
                                           {"name" => @op3.name,    "id" => @op3.id,    "stars" => "*",   "privilege" => Operator::PRIVILEGE_SUPER_OPERATOR_LEVEL_1, "in_formation"=>false, "color"=>"#ffffff", "presences" => [], "review_presences" => []},
                                           {"name" => @op4.name,    "id" => @op4.id,    "stars" => "**",  "privilege" => Operator::PRIVILEGE_SUPER_OPERATOR_LEVEL_2, "in_formation"=>false, "color"=>"#ffffff", "presences" => [], "review_presences" => []}
                                       ]
                                   })

      end

      it 'should render the correct csv to be downloaded' do
        @op1.operator_presences.create(date: DateTime.new(2015, 9, 10, 10, 00, 00))
        @op1.operator_presences.create(date: DateTime.new(2015, 9, 10, 10, 30, 00))
        @op1.operator_presences.create(date: DateTime.new(2015, 9, 11, 12, 00, 00))
        @op2.operator_presences.create(date: DateTime.new(2015, 9, 11, 12, 00, 00))

        expect(controller).to receive(:jd_auth_current_user).at_least(:once).and_return(OpenStruct.new(email: @user_admin))

        get :index, params: { start: DateTime.new(2015, 9, 10).to_s, format: :csv }
        expect(response.body).to eq(<<END
Semaine 36;Thursday;Friday;Saturday;Sunday;Monday;Tuesday;Wednesday;Count
#{@normal.name};;;;;;;;0.0
#{@op1.name};13h00 - 14h00;15h00 - 15h30;;;;;;1.5
#{@op2.name};;15h00 - 15h30;;;;;;0.5
#{@op3.name};;;;;;;;0.0
#{@op4.name};;;;;;;;0.0
#{@op5.name};;;;;;;;0.0
;
;
Semaine 36;Thursday;;;Friday;;;Saturday;;;Sunday;;;Monday;;;Tuesday;;;Wednesday;;;Total
#{@normal.name};0.0;0.0;0.0;0.0;0.0;0.0;0.0;0.0;0.0;0.0;0.0;0.0;0.0;0.0;0.0;0.0;0.0;0.0;0.0;0.0;0.0;0.0
#{@op1.name};1.0;0.0;1.0;0.5;0.0;0.5;0.0;0.0;0.0;0.0;0.0;0.0;0.0;0.0;0.0;0.0;0.0;0.0;0.0;0.0;0.0;1.5
#{@op2.name};0.0;0.0;0.0;0.5;0.0;0.5;0.0;0.0;0.0;0.0;0.0;0.0;0.0;0.0;0.0;0.0;0.0;0.0;0.0;0.0;0.0;0.5
#{@op3.name};0.0;0.0;0.0;0.0;0.0;0.0;0.0;0.0;0.0;0.0;0.0;0.0;0.0;0.0;0.0;0.0;0.0;0.0;0.0;0.0;0.0;0.0
#{@op4.name};0.0;0.0;0.0;0.0;0.0;0.0;0.0;0.0;0.0;0.0;0.0;0.0;0.0;0.0;0.0;0.0;0.0;0.0;0.0;0.0;0.0;0.0
#{@op5.name};0.0;0.0;0.0;0.0;0.0;0.0;0.0;0.0;0.0;0.0;0.0;0.0;0.0;0.0;0.0;0.0;0.0;0.0;0.0;0.0;0.0;0.0
END
)
      end
    end

    describe 'Add' do
      it 'should access the index page if the operator has admin privileges' do
        expect(controller).to receive(:jd_auth_current_user).at_least(:once).and_return(OpenStruct.new(email: @user_admin))

        post :add, params: { presences: [] }
        expect(response.body).to eq('{}')
      end

      it 'should not access the index page if the operator has not admin privileges' do
        expect(controller).to receive(:jd_auth_current_user).at_least(:once).and_return(OpenStruct.new(email: @user_non_admin))
        post :add
        expect(response).to redirect_to(root_path)
      end

      it 'should add a new operator presence' do
        expect(@op1.operator_presences.size).to eq(0)

        expect(controller).to receive(:jd_auth_current_user).at_least(:once).and_return(OpenStruct.new(email: @user_admin))

        post :add, params: { operator_id: @op1, presences: [DateTime.new(2015, 10, 10).to_s, DateTime.new(2015, 10, 12).to_s, DateTime.new(2015, 10, 13).to_s, DateTime.new(2015, 10, 14).to_s] }

        @op1.reload
        expect(@op1.operator_presences.size).to eq(4)
        expect(@op1.operator_presences.map{|op| op.date.to_s}).to eq(["2015-10-10 00:00:00 UTC", "2015-10-12 00:00:00 UTC", "2015-10-13 00:00:00 UTC", "2015-10-14 00:00:00 UTC"])
      end

      it 'should replace an existing presence if there is one on the same date' do
        @op1.operator_presences.create(date: DateTime.new(2015, 10, 12))
        expect(@op1.operator_presences.size).to eq(1)

        expect(controller).to receive(:jd_auth_current_user).at_least(:once).and_return(OpenStruct.new(email: @user_admin))

        post :add, params: { operator_id: @op1, presences: [DateTime.new(2015, 10, 10).to_s, DateTime.new(2015, 10, 12).to_s, DateTime.new(2015, 10, 13).to_s, DateTime.new(2015, 10, 14).to_s] }

        @op1.reload
        expect(@op1.operator_presences.size).to eq(4)
        expect(@op1.operator_presences.map{|op| op.date.to_s}).to eq(["2015-10-10 00:00:00 UTC", "2015-10-12 00:00:00 UTC", "2015-10-13 00:00:00 UTC", "2015-10-14 00:00:00 UTC"])
      end

      it 'should add a new presence to the existing ones' do

        @op1.operator_presences.create(date: DateTime.new(2015, 10, 12))
        @op1.operator_presences.create(date: DateTime.new(2015, 10, 13))
        @op1.operator_presences.create(date: DateTime.new(2015, 10, 14))
        @op1.operator_presences.create(date: DateTime.new(2015, 10, 15))
        expect(@op1.operator_presences.size).to eq(4)

        expect(controller).to receive(:jd_auth_current_user).at_least(:once).and_return(OpenStruct.new(email: @user_admin))

        post :add, params: { operator_id: @op1, presences: [DateTime.new(2015, 10, 16).to_s] }

        @op1.reload
        expect(@op1.operator_presences.size).to eq(5)
        expect(@op1.operator_presences.map{|op| op.date.to_s}).to eq(["2015-10-12 00:00:00 UTC", "2015-10-13 00:00:00 UTC", "2015-10-14 00:00:00 UTC", "2015-10-15 00:00:00 UTC", "2015-10-16 00:00:00 UTC"])
      end
    end

    describe 'Copy Day' do

      it ' should raise the correct exception if no day is provided as parameter' do
        expect {
          expect(controller).to receive(:jd_auth_current_user).at_least(:once).and_return(OpenStruct.new(email: @user_admin))
          post :copy_day
        }.to raise_error(RuntimeError, 'no day given')
      end

      it 'should copy the all the Operator Presences from a day to another one 3 days later' do
        @op1.operator_presences.create(date: DateTime.new(2015, 10, 12, 17, 00, 00))
        @op1.operator_presences.create(date: DateTime.new(2015, 10, 12, 23, 00, 00))
        @op1.operator_presences.create(date: DateTime.new(2015, 10, 13, 11, 00, 00))
        @op2.operator_presences.create(date: DateTime.new(2015, 10, 12, 17, 00, 00))
        @op2.operator_presences.create(date: DateTime.new(2015, 10, 12, 23, 00, 00))
        @op2.operator_presences.create(date: DateTime.new(2015, 10, 13, 11, 00, 00))

        expect(@op1.operator_presences.size).to eq(3)
        expect(@op2.operator_presences.size).to eq(3)

        expect(controller).to receive(:jd_auth_current_user).at_least(:once).and_return(OpenStruct.new(email: @user_admin))

        post :copy_day, params: { day: DateTime.new(2015, 10, 12, 17, 00, 00), days: 3 }

        expect(@op1.operator_presences.size).to eq(6)
        expect(@op2.operator_presences.size).to eq(6)

        @op1.reload
        @op2.reload
        expect(@op1.operator_presences.last(3).map{|op| op.date.to_s}).to eq(["2015-10-15 17:00:00 UTC", "2015-10-15 23:00:00 UTC", "2015-10-16 11:00:00 UTC"])
        expect(@op2.operator_presences.last(3).map{|op| op.date.to_s}).to eq(["2015-10-15 17:00:00 UTC", "2015-10-15 23:00:00 UTC", "2015-10-16 11:00:00 UTC"])
      end
    end

    describe 'Reset Day' do
      it ' should raise the correct exception if no day is provided as parameter' do
        expect {
          expect(controller).to receive(:jd_auth_current_user).at_least(:once).and_return(OpenStruct.new(email: @user_admin))
          post :reset_day
        }.to raise_error(RuntimeError, 'no day given')
      end

      it 'should delete all the operators presences for a given day' do
        @op1.operator_presences.create(date: DateTime.new(2015, 10, 12, 16, 00, 00))
        @op1.operator_presences.create(date: DateTime.new(2015, 10, 12, 17, 00, 00))
        @op1.operator_presences.create(date: DateTime.new(2015, 10, 12, 23, 00, 00))
        @op1.operator_presences.create(date: DateTime.new(2015, 10, 13, 11, 00, 00))
        @op2.operator_presences.create(date: DateTime.new(2015, 10, 12, 16, 00, 00))
        @op2.operator_presences.create(date: DateTime.new(2015, 10, 12, 17, 00, 00))
        @op2.operator_presences.create(date: DateTime.new(2015, 10, 12, 23, 00, 00))
        @op2.operator_presences.create(date: DateTime.new(2015, 10, 13, 11, 00, 00))

        expect(@op1.operator_presences.size).to eq(4)
        expect(@op2.operator_presences.size).to eq(4)

        expect{
          expect(controller).to receive(:jd_auth_current_user).at_least(:once).and_return(OpenStruct.new(email: @user_admin))
          post :reset_day, params: { day: DateTime.new(2015, 10, 12, 17, 00, 00) }
        }.to change{OperatorPresence.count}.by(-6)

        expect(@op1.operator_presences.size).to eq(1)
        expect(@op2.operator_presences.size).to eq(1)
      end
    end

    describe 'Remove' do
      it 'should remove the specified presences for the specified operator' do
        @op1.operator_presences.create(date: DateTime.new(2015, 10, 12, 16, 00, 00))
        @op1.operator_presences.create(date: DateTime.new(2015, 10, 12, 17, 00, 00))
        @op1.operator_presences.create(date: DateTime.new(2015, 10, 12, 23, 00, 00))
        @op1.operator_presences.create(date: DateTime.new(2015, 10, 13, 11, 00, 00))

        expect(@op1.operator_presences.size).to eq(4)

        expect{
          expect(controller).to receive(:jd_auth_current_user).at_least(:once).and_return(OpenStruct.new(email: @user_admin))
          post :remove, params: { operator_id: @op1.id, presences: [DateTime.new(2015, 10, 12, 16, 00, 00).to_s, DateTime.new(2015, 10, 12, 23, 00, 00).to_s] }
        }.to change{OperatorPresence.count}.by(-2)

        @op1.reload
        expect(@op1.operator_presences.size).to eq(2)
        expect(@op1.operator_presences.map{|op| op.date.to_s}).to eq(["2015-10-12 17:00:00 UTC", "2015-10-13 11:00:00 UTC"])
      end
    end

    describe 'upload_planning_constraints' do

      it 'should upload the file to S3' do
        start_date = ActiveSupport::TimeZone.new('UTC').parse('2016/01/01T15:00:00')

        allow(Time).to receive(:now).and_return(Time.new(2016,01,01,12,00,00))

        allow_any_instance_of(AiProxy).to receive(:build_request).with(:initiate_planning, { n_new_clients: "", productivity: "5", filename: "planning_constraints_01-01-2016T12:00:00.csv", date: start_date.to_s }).and_return({})

        allow(controller).to receive(:handle_planning_ai_data).with({"start_date"=>"2016-01-01 15:00:00 UTC"})

        expect(controller).to receive(:jd_auth_current_user).at_least(:once).and_return(OpenStruct.new(email: @user_admin))

        expect(Uploaders::AmazonAws).to receive(:store_file).with("planning_constraints_01-01-2016T12:00:00.csv", "test")

        post :upload_planning_constraints, params: {file: "test", productivity: 5, start_date: start_date, n_new_clients: nil}
      end

      it 'should send the correct request to the AI' do
        start_date = ActiveSupport::TimeZone.new('UTC').parse('2016/01/01T15:00:00')

        allow(Time).to receive(:now).and_return(Time.new(2016,01,01,12,00,00))

        expect_any_instance_of(AiProxy).to receive(:build_request).with(:initiate_planning, { n_new_clients: "", productivity: "5", filename: "planning_constraints_01-01-2016T12:00:00.csv", date: start_date.to_s }).and_return({})

        allow(controller).to receive(:handle_planning_ai_data).with({"start_date"=>"2016-01-01 15:00:00 UTC"})

        allow(Uploaders::AmazonAws).to receive(:store_file).with("planning_constraints_01-01-2016T12:00:00.csv", "test")

        expect(controller).to receive(:jd_auth_current_user).at_least(:once).and_return(OpenStruct.new(email: @user_admin))

        post :upload_planning_constraints, params: {file: "test", productivity: 5, start_date: start_date, n_new_clients: nil}
      end

      it 'should call the correct method to handle the planning data' do
        start_date = ActiveSupport::TimeZone.new('UTC').parse('2016/01/01T15:00:00')

        allow(Time).to receive(:now).and_return(Time.new(2016,01,01,12,00,00))

        allow_any_instance_of(AiProxy).to receive(:build_request).with(:initiate_planning, { n_new_clients: "", productivity: "5", filename: "planning_constraints_01-01-2016T12:00:00.csv", date: start_date.to_s }).and_return({})

        expect(controller).to receive(:handle_planning_ai_data).with({"start_date"=>"2016-01-01 15:00:00 UTC"})

        allow(Uploaders::AmazonAws).to receive(:store_file).with("planning_constraints_01-01-2016T12:00:00.csv", "test")

        expect(controller).to receive(:jd_auth_current_user).at_least(:once).and_return(OpenStruct.new(email: @user_admin))

        post :upload_planning_constraints, params: {file: "test", productivity: 5, start_date: start_date, n_new_clients: nil}
      end

      it 'should render the correct json' do
        start_date = ActiveSupport::TimeZone.new('UTC').parse('2016/01/01T15:00:00')

        allow(Time).to receive(:now).and_return(Time.new(2016,01,01,12,00,00))

        allow_any_instance_of(AiProxy).to receive(:build_request).with(:initiate_planning, { n_new_clients: "", productivity: "5", filename: "planning_constraints_01-01-2016T12:00:00.csv", date: start_date.to_s }).and_return({})

        allow(controller).to receive(:handle_planning_ai_data).with({"start_date"=>"2016-01-01 15:00:00 UTC"})

        allow(Uploaders::AmazonAws).to receive(:store_file).with("planning_constraints_01-01-2016T12:00:00.csv", "test")

        expect(controller).to receive(:jd_auth_current_user).at_least(:once).and_return(OpenStruct.new(email: @user_admin))

        post :upload_planning_constraints, params: {file: "test", productivity: 5, start_date: start_date, n_new_clients: nil}

        expect(response.body).to eq("{\"start_date\":\"2016-01-01 15:00:00 UTC\",\"filename\":\"planning_constraints_01-01-2016T12:00:00.csv\"}")
      end
    end

    describe 'get_planning_from_ai' do

      it 'should send the correct request to the AI' do
        start_date = ActiveSupport::TimeZone.new('UTC').parse('2016/01/01T15:00:00')
        filename = "planning_constraints_01-01-2016T12:00:00.csv"

        expect_any_instance_of(AiProxy).to receive(:build_request).with(:fetch_planning, { date: start_date.to_s, productivity: "5", filename: filename }).and_return({})
        allow(controller).to receive(:handle_planning_ai_data).with({"start_date"=>"2016-01-01 15:00:00 UTC"})

        expect(controller).to receive(:jd_auth_current_user).at_least(:once).and_return(OpenStruct.new(email: @user_admin))

        post :get_planning_from_ai, params: {filename: filename, productivity: 5, start_date: start_date}
      end

      it 'should send the correct request to the AI' do
        start_date = ActiveSupport::TimeZone.new('UTC').parse('2016/01/01T15:00:00')
        filename = "planning_constraints_01-01-2016T12:00:00.csv"

        allow_any_instance_of(AiProxy).to receive(:build_request).with(:fetch_planning, { date: start_date.to_s, productivity: "5", filename: filename }).and_return({})
        expect(controller).to receive(:handle_planning_ai_data).with({"start_date"=>"2016-01-01 15:00:00 UTC"})

        expect(controller).to receive(:jd_auth_current_user).at_least(:once).and_return(OpenStruct.new(email: @user_admin))

        post :get_planning_from_ai, params: {filename: filename, productivity: 5, start_date: start_date}
      end

      it 'should render the correct json' do
        start_date = ActiveSupport::TimeZone.new('UTC').parse('2016/01/01T15:00:00')
        filename = "planning_constraints_01-01-2016T12:00:00.csv"

        allow_any_instance_of(AiProxy).to receive(:build_request).with(:fetch_planning, { date: start_date.to_s, productivity: "5", filename: filename }).and_return({})
        allow(controller).to receive(:handle_planning_ai_data).with({"start_date"=>"2016-01-01 15:00:00 UTC"})

        expect(controller).to receive(:jd_auth_current_user).at_least(:once).and_return(OpenStruct.new(email: @user_admin))

        post :get_planning_from_ai, params: {filename: filename, productivity: 5, start_date: start_date}
        expect(response.body).to eq("{\"start_date\":\"2016-01-01 15:00:00 UTC\"}")
      end

    end

  end

  describe 'Methods' do
    before(:each) do

      @op1 = FactoryGirl.create(:operator_actif)
      @op2 = FactoryGirl.create(:operator_actif)
      @op3 = FactoryGirl.create(:operator_actif)
      @op4 = FactoryGirl.create(:operator_actif)
      @op5 = FactoryGirl.create(:operator_actif)

    end
    describe 'generate_operators_presence_data' do

      it 'should return the correct data' do
        @op1.operator_presences.create(date: DateTime.new(2015, 9, 10, 10, 00, 00))
        @op1.operator_presences.create(date: DateTime.new(2015, 9, 11, 12, 00, 00))
        @op2.operator_presences.create(date: DateTime.new(2015, 9, 11, 12, 00, 00))
        @op2.operator_presences.create(date: DateTime.new(2015, 9, 11, 13, 00, 00), is_review: true)

        @op3.privilege = Operator::PRIVILEGE_SUPER_OPERATOR_LEVEL_1
        @op3.save
        @op4.privilege = Operator::PRIVILEGE_SUPER_OPERATOR_LEVEL_2
        @op4.save

        expected =[
                {:name => @normal.name, :id => @normal.id, :stars => nil,   :privilege => nil, :in_formation=>false, :color=>"#ffffff", :presences => [], :review_presences => []},
                {:name => @op1.name,    :id => @op1.id,    :stars => nil,   :privilege => nil, :in_formation=>false, :color=>"#ffffff", :presences => ["20150910T100000", "20150911T120000"], :review_presences => []},
                {:name => @op2.name,    :id => @op2.id,    :stars => nil,   :privilege => nil, :in_formation=>false, :color=>"#ffffff", :presences => ["20150911T120000"], :review_presences => ["20150911T130000"]},
                {:name => @op5.name,    :id => @op5.id,    :stars => nil,   :privilege => nil, :in_formation=>false, :color=>"#ffffff", :presences => [], :review_presences => []},
                {:name => @op3.name,    :id => @op3.id,    :stars => "*",   :privilege => Operator::PRIVILEGE_SUPER_OPERATOR_LEVEL_1, :in_formation=>false, :color=>"#ffffff", :presences => [], :review_presences => []},
                {:name => @op4.name,    :id => @op4.id,    :stars => "**",  :privilege => Operator::PRIVILEGE_SUPER_OPERATOR_LEVEL_2, :in_formation=>false, :color=>"#ffffff", :presences => [], :review_presences => []}
            ]

        expect(controller.send(:generate_operators_presence_data, DateTime.new(2015, 9, 10))).to eq(expected)
      end

    end

    describe 'clean_operator_presences_for_week' do

      it 'should destroy the correct OperatorPresences' do
        @op1.operator_presences.create(date: DateTime.new(2015, 9, 10, 10, 00, 00))
        @op1.operator_presences.create(date: DateTime.new(2015, 9, 11, 12, 00, 00))
        @op2.operator_presences.create(date: DateTime.new(2015, 9, 11, 12, 00, 00))
        @op2.operator_presences.create(date: DateTime.new(2015, 9, 11, 13, 00, 00), is_review: true)
        @op2.operator_presences.create(date: DateTime.new(2015, 9, 9, 13, 00, 00), is_review: true)
        @op2.operator_presences.create(date: DateTime.new(2015, 9, 9, 14, 00, 00), is_review: true)
        @op2.operator_presences.create(date: DateTime.new(2015, 9, 9, 15, 00, 00), is_review: true)

        @op3.privilege = Operator::PRIVILEGE_SUPER_OPERATOR_LEVEL_1
        @op3.save
        @op4.privilege = Operator::PRIVILEGE_SUPER_OPERATOR_LEVEL_2
        @op4.save


        expect{
          controller.send(:clean_operator_presences_for_week, DateTime.new(2015, 9, 10))
        }.to change{OperatorPresence.count}.by(-4)

      end
    end

    describe 'handle_planning_ai_data' do
      it 'should call the right methods' do

        forecast = 'forecast'
        planning = 'planning'
        start_date = Time.new(2016,01,01,15,00,00)


        MySettings['planning.operator_hourly_productivity'] = 5

        expect(AiEmailFlowForecast).to receive(:handle_forecast_data).with(forecast)
        expect(controller).to receive(:handle_new_planning_data).with(start_date.to_s, planning)


        controller.send(:handle_planning_ai_data, {'start_date' => start_date.to_s, 'forecast' => forecast, 'planning' => planning, 'productivity' => 7})

        expect(MySettings['planning.operator_hourly_productivity']).to eq(7)
      end

      it 'should modify the params hash in place' do
        forecast = 'forecast'
        planning = 'planning'
        start_date = Time.new(2016,01,01,15,00,00)
        params = {'start_date' => start_date.to_s, 'forecast' => forecast, 'planning' => planning, 'productivity' => 7}

        allow(AiEmailFlowForecast).to receive(:handle_forecast_data).with(forecast).and_return('returned_forecast')
        allow(controller).to receive(:handle_new_planning_data).with(start_date.to_s, planning).and_return('returned_planning')

        controller.send(:handle_planning_ai_data, params)

        expect(params).to eq({'start_date' => start_date.to_s, 'forecast' => 'returned_forecast', 'planning' => 'returned_planning', 'productivity' => 7})
      end
    end

    describe 'handle_new_planning_data' do

      it 'should create the correct operator presences' do

        start_date = "2016-6-13"
        data = {@op1.id =>[
            [0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 1, 1, 1, 1, 1, 1, 1, 1, 0, 1, 1, 1, 1, 1, 1, 1, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0],
            [0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 1, 1, 1, 1, 1, 1, 1, 1, 1, 0, 1, 1, 1, 1, 1, 1, 1, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0],
            [0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 1, 1, 1, 1, 1, 1, 1, 1, 0, 1, 1, 1, 1, 1, 1, 1, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0],
            [0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 1, 1, 1, 1, 1, 1, 1, 1, 0, 1, 1, 1, 1, 1, 1, 1, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0],
            [0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 1, 1, 1, 1, 1, 1, 1, 1, 0, 1, 1, 1, 1, 1, 1, 1, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0],
            [0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0],
            [0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0]
        ]}

        expect(controller).to receive(:generate_operators_presence_data).with(ActiveSupport::TimeZone.new('UTC').parse(start_date).change(hour: 3))

        expect{
          controller.send(:handle_new_planning_data,start_date, data)
        }.to change{OperatorPresence.count}.by(76)
      end

    end
  end
end