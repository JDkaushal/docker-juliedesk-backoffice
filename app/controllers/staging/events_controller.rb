if ENV['STAGING_APP']
  module Staging

    class EventsController < StagingController

      def save_attendees
        query_result = StagingHelpers::MessagesThreadsHelper.save_attendees(params[:event_id], params[:attendees])

        render json: {
                   success: query_result.result_error_message.size == 0
               }
      end

      def get_attendees
        query = StagingHelpers::MessagesThreadsHelper.get_attendees(params[:event_id])

        render json: {
                   success: query[:success],
                   data: (query[:result] || []).map{|attendee| {email: attendee['email'], name: attendee['name']} }
               }
      end
    end
  end
end