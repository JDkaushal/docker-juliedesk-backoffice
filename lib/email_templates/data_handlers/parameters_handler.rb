module EmailTemplates
  module DataHandlers
    class ParametersHandler

      def initialize(params)
        @params = params
      end

      def get_language
        @params['language']
      end

      def get_attendees
        @params['participants']
      end

      def get_attendees_without_thread_owner
        @params['participants'] && @params['participants'].reject{|att| att['isThreadOwner']}
      end

      def get_thread_owner
        @params['participants'] && @params['participants'].find{|att| att['isThreadOwner']}
      end

      def get_suggested_dates
        @params['suggested_dates'].map{|d| d.to_time.in_time_zone(get_timezone)}.group_by{|d| d.to_date}
      end

      def get_suggested_dates_count
        @params['suggested_dates'].size
      end

      def get_clients
        @params['participants'].select{|att| att['isClient']}
      end

      def get_clients_count
        1
      end

      def get_attendees_count
        @params['participants'].size
      end

      def get_appointment_type
        @params['appointment']
      end

      def get_location
        @params['location']
      end

      def get_julie_alias_footer
        @params['julie_alias'].send("footer_#{I18n.locale}")
      end

      def get_timezone
        @params['timezone']
      end

      def get_validated_date
        Time.parse(@params['validate']).in_time_zone(get_timezone)
      end

    end
  end
end
