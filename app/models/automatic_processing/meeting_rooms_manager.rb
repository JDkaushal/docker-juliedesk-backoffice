module AutomaticProcessing

  class MeetingRoomsManager

    attr_reader :data_holder

    def initialize(data_holder)
      @data_holder = data_holder
    end

    def get_meeting_rooms_params
      request_details = {meeting_rooms_to_show: {}, grouped_meeting_rooms_to_show: {}}
      current_appointment = @data_holder.get_appointment
      current_address = @data_holder.get_address

      current_address_is_default_for_appointment = current_appointment['default_address'].try(:[], 'address') == current_address['address']
      meeting_rooms_used_for_current_appointment = current_appointment['meeting_room_used']
      meeting_rooms_used_for_current_address = current_address['meeting_room_used'] && current_address['meeting_rooms_enabled']

      if ((current_address_is_default_for_appointment && meeting_rooms_used_for_current_appointment) || (meeting_rooms_used_for_current_address))
        room_selected = determine_used_meeting_room(current_appointment['selected_meeting_room'] || '', current_address['selected_meeting_room'] || '')

        if room_selected.include?('auto_room_selection')
          rooms = filter_available_rooms(room_selected.split('|')[-1])
          grouped_rooms = rooms.group_by{|r| r['calendar_login_username']}
          grouped_rooms.each{ |k, v| request_details[:meeting_rooms_to_show][k] = v.map{ |r| r['id'] } }
          request_details[:grouped_meeting_rooms_to_show][1] = rooms.map{ |r| r['id'] }
        else
          room = find_room(room_selected)
          request_details[:meeting_rooms_to_show][room['calendar_login_username']] = [room_selected]
          request_details[:grouped_meeting_rooms_to_show][1] = [room_selected]
        end
      end


      request_details
    end


    private

    def determine_used_meeting_room(appointment_meeting_room_config, current_address_meeting_room_config)
      used_meeting_room = appointment_meeting_room_config;

      if !appointment_meeting_room_config.include?('auto_room_selection')
          used_meeting_room = appointment_meeting_room_config
      elsif !current_address_meeting_room_config.include?('auto_room_selection')
          used_meeting_room = current_address_meeting_room_config
      else
          used_meeting_room = compute_default_filters(appointment_meeting_room_config, current_address_meeting_room_config)
      end

      used_meeting_room
    end

    def filter_available_rooms(filters_to_apply)
      filters = filters_to_apply.split(';')
      attendees_count = @data_holder.get_attendees_count

      available_meeting_rooms = @data_holder.get_address['available_meeting_rooms']
      available_meeting_rooms.reject do |room|
        filters.any?{ |filter| !pass_filters(filter, room, {attendees_count: attendees_count}) }
      end
    end

    def pass_filters(filter, room, filter_params = {})
      case filter
        when 'attendees_count'
          (room['capacity'] || 99999) >= (filter_params[:attendees_count] || 0)
        when 'can_confcall'
          room['can_confcall']
        when 'can_visio'
          room['can_visio']
      end
    end

    def compute_default_filters(appointment_meeting_room_config, current_address_meeting_room_config)
      filters_from_appointments = appointment_meeting_room_config.split('|')[1].split(';')
      filters_from_address = current_address_meeting_room_config.split('|')[1].split(';')

      summed_filters = (filters_from_appointments + filters_from_address).uniq

      "auto_room_selection|#{summed_filters.join(';')}"
    end

    def find_room(room_email)
      @data_holder.get_all_available_meeting_rooms.find{|r| r["id"] == room_email}
    end
  end
end