module Ai
  module DataHandlers
    class AttendeesHandler

      def initialize(client_account, attendees)
        @attendees = attendees
        @client_email = client_account.email
        @default_timezone = client_account.default_timezone_id
      end

      def handle
        @attendees.each do |attendee|
          handle_attendee(attendee)
        end
      end

      private

      def handle_attendee(attendee)

        params = {
            email: attendee['email'],
            first_name: attendee['firstName'],
            last_name: attendee['lastName'],
            usage_name: attendee['first_name'],
            gender: attendee['gender'],
            is_assistant: false,
            assisted: false,
            assisted_by: nil,
            company: attendee['company'] || '',
            timezone: @default_timezone,
            landline: attendee['landline'],
            mobile: attendee['mobile'],
            skypeId: attendee['skypeId'],
            need_ai_confirmation: false,
            ai_has_been_confirmed: true
        }

        if client_contact = ClientContact.find_by(client_email: @client_email, email: attendee['email'])
          client_contact.assign_attributes(params)
        else
          client_contact = ClientContact.new(
              client_email: @client_email
          )

          client_contact.assign_attributes(params)
        end

        client_contact.save
      end
    end
  end
end
