module EventsManagement
  module Utilities
    class BaseGenerator

      def initialize(locale)
        # When arriving here we already generated the email template so made sure the locale was correct
      I18n.locale = locale
      end

    end
  end
end