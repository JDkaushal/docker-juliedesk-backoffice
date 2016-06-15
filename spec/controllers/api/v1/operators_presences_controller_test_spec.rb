require_relative "../../../rails_helper"

describe Api::V1::OperatorsPresencesController, :type => :controller do

  describe 'Inheritance' do
    it { expect(described_class).to be < Api::ApiV1Controller }
  end

  describe 'Operators count for a given time' do
    before do
      request.headers['Authorization'] = 'EDx19D72bH7e5I64EXk1kwa4jXvynddS'
    end

    describe 'No date provided' do
      before(:each) do
        expect(DateTime).to receive(:now).and_return(DateTime.new(2015, 11, 25, 12, 23, 00))
      end

      it 'should fallback to the current time if no time is provided' do
        expect(Pusher).to receive(:get).and_return(users: [])

        # We just check if DateTime receive the method Now in the before filter
        get :operators_count_at_time
      end

      it 'should return the correct data' do
        op1 = FactoryGirl.create(:operator_actif)
        op2 = FactoryGirl.create(:operator_actif)
        op3 = FactoryGirl.create(:operator_actif)
        op4 = FactoryGirl.create(:operator_actif)
        op5 = FactoryGirl.create(:operator_actif)

        op1.operator_presences.create(date: DateTime.new(2015, 11, 25, 12, 00, 00))
        op2.operator_presences.create(date: DateTime.new(2015, 11, 25, 12, 00, 00))
        op3.operator_presences.create(date: DateTime.new(2015, 11, 25, 12, 00, 00))
        op4.operator_presences.create(date: DateTime.new(2015, 11, 25, 12, 00, 00))
        op5.operator_presences.create(date: DateTime.new(2015, 11, 25, 12, 00, 00))
        op5.operator_presences.create(date: DateTime.new(2015, 11, 26, 16, 00, 00), is_review: true)

        expect(Pusher).to receive(:get).and_return(users: [
                                                       {'id' => op1.email},
                                                       {'id' => op2.email},
                                                       {'id' => op3.email},
                                                       {'id' => op4.email},
                                                       {'id' => op5.email}
                                                   ])
        get :operators_count_at_time

        expect(JSON.parse(response.body)).to eq(
                                                 {
                                                     "status" => "success",
                                                     "data" => {
                                                         "operators_count" => 5,
                                                         "operators" => [
                                                             {"name" => "operatorName1", "email" => "person1@example.com", "present" => true, "operator_id" => 1},
                                                             {"name" => "operatorName2", "email" => "person2@example.com", "present" => true, "operator_id" => 2},
                                                             {"name" => "operatorName3", "email" => "person3@example.com", "present" => true, "operator_id" => 3},
                                                             {"name" => "operatorName4", "email" => "person4@example.com", "present" => true, "operator_id" => 4},
                                                             {"name" => "operatorName5", "email" => "person5@example.com", "present" => true, "operator_id" => 5}
                                                         ]
                                                     }
                                                 }
                                             )
      end
    end

    describe 'Date provided' do

      it 'should return the correct data' do
        op1 = FactoryGirl.create(:operator_actif)
        op2 = FactoryGirl.create(:operator_actif)
        op3 = FactoryGirl.create(:operator_actif)
        op4 = FactoryGirl.create(:operator_actif)
        op5 = FactoryGirl.create(:operator_actif)

        op1.operator_presences.create(date: DateTime.new(2015, 11, 25, 12, 00, 00))
        op2.operator_presences.create(date: DateTime.new(2015, 11, 26, 15, 00, 00))
        op3.operator_presences.create(date: DateTime.new(2015, 11, 26, 15, 00, 00))
        op4.operator_presences.create(date: DateTime.new(2015, 11, 26, 15, 00, 00))
        op5.operator_presences.create(date: DateTime.new(2015, 11, 26, 15, 00, 00))
        op5.operator_presences.create(date: DateTime.new(2015, 11, 26, 16, 00, 00), is_review: true)

        expect(Pusher).to receive(:get).and_return(users: [{'id' => op1.email}, {'id' => op3.email}, {'id' => op4.email}, {'id' => op5.email}])

        get :operators_count_at_time, {date: "2015-11-26T15:14:00+00:00"}

        expect(JSON.parse(response.body)).to eq({
                                        "status" => "success",
                                        "data" => {
                                            "operators_count" => 4,
                                            "operators" => [
                                                {
                                                    "name" => "#{op2.name}",
                                                    "email" => "#{op2.email}",
                                                    "present" => false,
                                                    "operator_id" => op2.id,
                                                },
                                                {
                                                    "name" => "#{op3.name}",
                                                    "email" => "#{op3.email}",
                                                    "present" => true,
                                                    "operator_id" => op3.id
                                                },
                                                {
                                                    "name" => "#{op4.name}",
                                                    "email" => "#{op4.email}",
                                                    "present" => true,
                                                    "operator_id" => op4.id
                                                },
                                                {
                                                    "name" => "#{op5.name}",
                                                    "email" => "#{op5.email}",
                                                    "present" => true,
                                                    "operator_id" => op5.id
                                                }
                                            ]
                                        }
                                    })
      end
    end
  end

end