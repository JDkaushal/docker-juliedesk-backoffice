require_relative "../../rails_helper"

describe Review::OperatorsPresenceController, :type => :controller do

  before(:each) do
    @admin = Operator.new(email: 'admin@op.com', privilege: 'admin', active: true)
    @admin.password= 'op'
    @admin.save

    @normal = Operator.new(email: 'normal@op.com', active: true, name: 'normal op')
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
      @request.env['HTTP_AUTHORIZATION'] = ActionController::HttpAuthentication::Basic.encode_credentials(@user_admin,@pw)

      @op1 = FactoryGirl.create(:operator_actif)
      @op2 = FactoryGirl.create(:operator_actif)
      @op3 = FactoryGirl.create(:operator_actif)
      @op4 = FactoryGirl.create(:operator_actif)
      @op5 = FactoryGirl.create(:operator_actif)

    end

    describe 'Index' do
      render_views

      it 'should access the index page if the operator has admin privileges' do
        get :index
        expect(response).to render_template(:index)
      end

      it 'should not access the index page if the operator has not admin privileges' do
        @request.env['HTTP_AUTHORIZATION'] = ActionController::HttpAuthentication::Basic.encode_credentials(@user_non_admin,@pw)
        get :index
        expect(response).to redirect_to(root_path)
      end



      it 'should populate the correct instance variables' do
        get :index, start: Time.now

        expect(assigns(:operators).map(&:id)).to eq([@normal.id, @op1.id, @op2.id, @op3.id, @op4.id, @op5.id])
      end

      it 'should return the correct html if a start parameter is provided' do
        @op1.operator_presences.create(date: DateTime.new(2015, 9, 10, 10, 00, 00))
        @op1.operator_presences.create(date: DateTime.new(2015, 9, 11, 12, 00, 00))
        @op2.operator_presences.create(date: DateTime.new(2015, 9, 11, 12, 00, 00))


        get :index, start: DateTime.new(2015, 9, 10)
        expect(response.body).to eq(<<END
Semaine 37;Thursday;Friday;Saturday;Sunday;Monday;Tuesday;Wednesday;Thursday;Count
#{@normal.name};;;;;;;;0
#{@op1.name};13h - 14h;15h - 16h;;;;;;2
#{@op2.name};;15h - 16h;;;;;;1
#{@op3.name};;;;;;;;0
#{@op4.name};;;;;;;;0
#{@op5.name};;;;;;;;0
END
)
      end

      it 'should render the correct json' do
        @op1.operator_presences.create(date: DateTime.new(2015, 9, 10, 10, 00, 00))
        @op1.operator_presences.create(date: DateTime.new(2015, 9, 11, 12, 00, 00))
        @op2.operator_presences.create(date: DateTime.new(2015, 9, 11, 12, 00, 00))

        @op3.privilege = Operator::PRIVILEGE_SUPER_OPERATOR_LEVEL_1
        @op3.save
        @op4.privilege = Operator::PRIVILEGE_SUPER_OPERATOR_LEVEL_2
        @op4.save

        get :index, start: DateTime.new(2015, 9, 10).to_s, format: :json

        body = JSON.parse response.body
        expect(body['status']).to eq("success")
        expect(body['data']).to eq({
                                       "operators" => [
                                           {"name" => @normal.name, "id" => @normal.id, "stars" => nil,   "presences" => []},
                                           {"name" => @op1.name,    "id" => @op1.id,    "stars" => nil,   "presences" => ["20150910T100000", "20150911T120000"]},
                                           {"name" => @op2.name,    "id" => @op2.id,    "stars" => nil,   "presences" => ["20150911T120000"]},
                                           {"name" => @op5.name,    "id" => @op5.id,    "stars" => nil,   "presences" => []},
                                           {"name" => @op3.name,    "id" => @op3.id,    "stars" => "*",   "presences" => []},
                                           {"name" => @op4.name,    "id" => @op4.id,    "stars" => "**",  "presences" => []}
                                       ]
                                   })

      end

      it 'should render the correct csv to be downloaded' do
        @op1.operator_presences.create(date: DateTime.new(2015, 9, 10, 10, 00, 00))
        @op1.operator_presences.create(date: DateTime.new(2015, 9, 11, 12, 00, 00))
        @op2.operator_presences.create(date: DateTime.new(2015, 9, 11, 12, 00, 00))

        get :index, start: DateTime.new(2015, 9, 10).to_s, format: :csv
        expect(response.body).to eq("Semaine 37;Thursday;Friday;Saturday;Sunday;Monday;Tuesday;Wednesday;Thursday;Count\n#{@normal.name};;;;;;;;0\n#{@op1.name};13h - 14h;15h - 16h;;;;;;2\n#{@op2.name};;15h - 16h;;;;;;1\n#{@op3.name};;;;;;;;0\n#{@op4.name};;;;;;;;0\n#{@op5.name};;;;;;;;0\n")
      end
    end

    describe 'Add' do
      it 'should access the index page if the operator has admin privileges' do
        post :add, presences: []
        expect(response.body).to eq('{}')
      end

      it 'should not access the index page if the operator has not admin privileges' do
        @request.env['HTTP_AUTHORIZATION'] = ActionController::HttpAuthentication::Basic.encode_credentials(@user_non_admin,@pw)
        post :add
        expect(response).to redirect_to(root_path)
      end

      it 'should add a new operator presence' do
        expect(@op1.operator_presences.size).to eq(0)

        post :add, operator_id: @op1, presences: [DateTime.new(2015, 10, 10).to_s, DateTime.new(2015, 10, 12).to_s, DateTime.new(2015, 10, 13).to_s, DateTime.new(2015, 10, 14).to_s]

        @op1.reload
        expect(@op1.operator_presences.size).to eq(4)
        expect(@op1.operator_presences.map{|op| op.date.to_s}).to eq(["2015-10-10 00:00:00 UTC", "2015-10-12 00:00:00 UTC", "2015-10-13 00:00:00 UTC", "2015-10-14 00:00:00 UTC"])
      end

      it 'should replace an existing presence if there is one on the same date' do
        @op1.operator_presences.create(date: DateTime.new(2015, 10, 12))
        expect(@op1.operator_presences.size).to eq(1)

        post :add, operator_id: @op1, presences: [DateTime.new(2015, 10, 10).to_s, DateTime.new(2015, 10, 12).to_s, DateTime.new(2015, 10, 13).to_s, DateTime.new(2015, 10, 14).to_s]

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

        post :add, operator_id: @op1, presences: [DateTime.new(2015, 10, 16).to_s]

        @op1.reload
        expect(@op1.operator_presences.size).to eq(5)
        expect(@op1.operator_presences.map{|op| op.date.to_s}).to eq(["2015-10-12 00:00:00 UTC", "2015-10-13 00:00:00 UTC", "2015-10-14 00:00:00 UTC", "2015-10-15 00:00:00 UTC", "2015-10-16 00:00:00 UTC"])
      end
    end

    describe 'Copy Day' do

      it ' should raise the correct exception if no day is provided as parameter' do
        expect {
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

        post :copy_day, day: DateTime.new(2015, 10, 12, 17, 00, 00), days: 3

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
          post :reset_day, day: DateTime.new(2015, 10, 12, 17, 00, 00)
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
          post :remove, operator_id: @op1.id, presences: [DateTime.new(2015, 10, 12, 16, 00, 00).to_s, DateTime.new(2015, 10, 12, 23, 00, 00).to_s]
        }.to change{OperatorPresence.count}.by(-2)

        @op1.reload
        expect(@op1.operator_presences.size).to eq(2)
        expect(@op1.operator_presences.map{|op| op.date.to_s}).to eq(["2015-10-12 17:00:00 UTC", "2015-10-13 11:00:00 UTC"])
      end
    end
  end
end