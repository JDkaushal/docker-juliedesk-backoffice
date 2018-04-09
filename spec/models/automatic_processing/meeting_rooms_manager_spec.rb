require "rails_helper"

describe AutomaticProcessing::MeetingRoomsManager do
  let(:data_holder) { AutomaticProcessing::DataHolder.new(Message.new) }
  let(:address1) { '1 rue de la ville, 10000 La Ville' }
  let(:address2) { '1 rue du village, 20000 Le Village' }
  subject(:meeting_rooms_manager) { AutomaticProcessing::MeetingRoomsManager.new(data_holder) }

  describe 'get_meeting_rooms_params' do

    context 'should book some meeting rooms' do

      context 'current address is same as current default address and rooms booking is enabled on current appointment' do
        before(:each) do
          expect(data_holder).to receive(:get_attendees_count).and_return(2)
          expect(data_holder).to receive(:get_appointment).and_return({
                                                                        'default_address' => {'address' => address1},
                                                                        'meeting_room_used' => true,
                                                                        'meeting_room_enabled' => true,
                                                                        'selected_meeting_room' => 'auto_room_selection|attendees_count;can_confcall;can_visio'
                                                                      })
          expect(data_holder).to receive(:get_address).exactly(2).times.and_return({
                                                                    'address' => address1,
                                                                    'meeting_room_used' => true,
                                                                    'meeting_rooms_enabled' => true,
                                                                    'selected_meeting_room' => 'auto_room_selection|attendees_count;can_confcall;can_visio',
                                                                    'available_meeting_rooms' => [
                                                                        {
                                                                            "calendar_login_username"=>"google_company_meeting_room",
                                                                            "can_confcall"=>true,
                                                                            "can_visio"=>true,
                                                                            "capacity"=>nil,
                                                                            "id"=>"room1@email.com",
                                                                            "summary"=>"FREDDY'S ROOM",
                                                                            "floor"=>9,
                                                                            "in_main_location"=>false,
                                                                            "on_default_floor"=>false,
                                                                            "floor_location_score"=>0.09999999999999998
                                                                        },
                                                                        {
                                                                            "calendar_login_username"=>"google_company_meeting_room",
                                                                            "can_confcall"=>true,
                                                                            "can_visio"=>true,
                                                                            "capacity"=>nil,
                                                                            "id"=>"room2@email.com",
                                                                            "summary"=>"SKYWALKER'S",
                                                                            "floor"=>2,
                                                                            "in_main_location"=>false,
                                                                            "on_default_floor"=>false,
                                                                            "floor_location_score"=>0.8
                                                                        },
                                                                        {
                                                                            "calendar_login_username"=>"google_company_meeting_room",
                                                                            "can_confcall"=>nil,
                                                                            "can_visio"=>nil,
                                                                            "capacity"=>nil,
                                                                            "id"=>"room3@email.com",
                                                                            "summary"=>"ANAKIN'S",
                                                                            "floor"=>9,
                                                                            "in_main_location"=>false,
                                                                            "on_default_floor"=>false,
                                                                            "floor_location_score"=>0.09999999999999998
                                                                        }
                                                                    ]
                                                                  })
        end

        it 'should generate the correct params' do
          expect(meeting_rooms_manager.get_meeting_rooms_params).to eq({
                                                                           :meeting_rooms_to_show=>{
                                                                               "google_company_meeting_room"=>["room1@email.com", "room2@email.com"]
                                                                           },
                                                                           :grouped_meeting_rooms_to_show=>[["room1@email.com", "room2@email.com"]]
                                                                       })

        end
      end

      context 'current address is using some meeting rooms' do
        before(:each) do

          expect(data_holder).to receive(:get_attendees_count).and_return(2)
          expect(data_holder).to receive(:get_appointment).and_return({
                                                                          'default_address' => {'address' => address2},
                                                                          'meeting_room_used' => true,
                                                                          'meeting_room_enabled' => true,
                                                                          'selected_meeting_room' => 'auto_room_selection|attendees_count;can_confcall;can_visio'
                                                                      })
          expect(data_holder).to receive(:get_address).exactly(2).times.and_return({
                                                                      'address' => address1,
                                                                      'meeting_room_used' => true,
                                                                      'meeting_rooms_enabled' => true,
                                                                      'selected_meeting_room' => 'auto_room_selection|attendees_count;can_confcall;can_visio',
                                                                      'available_meeting_rooms' => [
                                                                          {
                                                                              "calendar_login_username"=>"google_company_meeting_room",
                                                                              "can_confcall"=>true,
                                                                              "can_visio"=>true,
                                                                              "capacity"=>nil,
                                                                              "id"=>"room1@email.com",
                                                                              "summary"=>"FREDDY'S ROOM",
                                                                              "floor"=>9,
                                                                              "in_main_location"=>false,
                                                                              "on_default_floor"=>false,
                                                                              "floor_location_score"=>0.09999999999999998
                                                                          },
                                                                          {
                                                                              "calendar_login_username"=>"google_company_meeting_room",
                                                                              "can_confcall"=>true,
                                                                              "can_visio"=>true,
                                                                              "capacity"=>nil,
                                                                              "id"=>"room2@email.com",
                                                                              "summary"=>"SKYWALKER'S",
                                                                              "floor"=>2,
                                                                              "in_main_location"=>false,
                                                                              "on_default_floor"=>false,
                                                                              "floor_location_score"=>0.8
                                                                          },
                                                                          {
                                                                              "calendar_login_username"=>"google_company_meeting_room",
                                                                              "can_confcall"=>nil,
                                                                              "can_visio"=>nil,
                                                                              "capacity"=>nil,
                                                                              "id"=>"room3@email.com",
                                                                              "summary"=>"ANAKIN'S",
                                                                              "floor"=>9,
                                                                              "in_main_location"=>false,
                                                                              "on_default_floor"=>false,
                                                                              "floor_location_score"=>0.09999999999999998
                                                                          }
                                                                      ]
                                                                  })
        end

        it 'should generate the correct params' do
          expect(meeting_rooms_manager.get_meeting_rooms_params).to eq({
                                                                           :meeting_rooms_to_show=>{
                                                                               "google_company_meeting_room"=>["room1@email.com", "room2@email.com"]
                                                                           },
                                                                           :grouped_meeting_rooms_to_show=>[["room1@email.com", "room2@email.com"]]
                                                                       })

        end
      end
    end

    context 'should not book any meeting rooms' do

      context 'current address is not the same as default address and booking rooms is disabled on the address' do

        before(:each) do
          expect(data_holder).to receive(:get_appointment).and_return({
                                                                          'default_address' => {'address' => address1},
                                                                          'meeting_room_used' => true,
                                                                          'meeting_room_enabled' => true,
                                                                          'selected_meeting_room' => 'auto_room_selection|attendees_count;can_confcall;can_visio'
                                                                      })
          expect(data_holder).to receive(:get_address).and_return({
                                                                      'address' => address2,
                                                                      'meeting_room_used' => false,
                                                                      'meeting_rooms_enabled' => false,
                                                                      'selected_meeting_room' => 'auto_room_selection|attendees_count;can_confcall;can_visio',
                                                                      'available_meeting_rooms' => [
                                                                          {
                                                                              "calendar_login_username"=>"google_company_meeting_room",
                                                                              "can_confcall"=>true,
                                                                              "can_visio"=>true,
                                                                              "capacity"=>nil,
                                                                              "id"=>"room1@email.com",
                                                                              "summary"=>"FREDDY'S ROOM",
                                                                              "floor"=>9,
                                                                              "in_main_location"=>false,
                                                                              "on_default_floor"=>false,
                                                                              "floor_location_score"=>0.09999999999999998
                                                                          },
                                                                          {
                                                                              "calendar_login_username"=>"google_company_meeting_room",
                                                                              "can_confcall"=>true,
                                                                              "can_visio"=>true,
                                                                              "capacity"=>nil,
                                                                              "id"=>"room2@email.com",
                                                                              "summary"=>"SKYWALKER'S",
                                                                              "floor"=>2,
                                                                              "in_main_location"=>false,
                                                                              "on_default_floor"=>false,
                                                                              "floor_location_score"=>0.8
                                                                          },
                                                                          {
                                                                              "calendar_login_username"=>"google_company_meeting_room",
                                                                              "can_confcall"=>nil,
                                                                              "can_visio"=>nil,
                                                                              "capacity"=>nil,
                                                                              "id"=>"room3@email.com",
                                                                              "summary"=>"ANAKIN'S",
                                                                              "floor"=>9,
                                                                              "in_main_location"=>false,
                                                                              "on_default_floor"=>false,
                                                                              "floor_location_score"=>0.09999999999999998
                                                                          }
                                                                      ]
                                                                  })
        end

        it 'should generate the correct params' do
          expect(meeting_rooms_manager.get_meeting_rooms_params).to eq({:meeting_rooms_to_show=>{}, :grouped_meeting_rooms_to_show=>[]})
        end
      end
    end
  end
end