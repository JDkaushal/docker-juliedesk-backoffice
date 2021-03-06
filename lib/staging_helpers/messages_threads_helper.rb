if ENV['STAGING_APP']
  module StagingHelpers

    class MessagesThreadsHelper

      def self.save_attendees(event_id, attendees)
        sql = "SELECT * FROM staging_event_attendees WHERE event_id='#{event_id}'"

        query_result = ActiveRecord::Base.connection.execute(sql)

        json_attendees = attendees.to_json

        if query_result.num_tuples > 0
          id = query_result.first['id']
          sql = "UPDATE staging_event_attendees SET attendees='#{json_attendees}' WHERE id=#{id}"
        else
          sql = "INSERT INTO staging_event_attendees (event_id, attendees) VALUES ('#{event_id}', '#{json_attendees}')"
        end

        ActiveRecord::Base.connection.execute(sql)
      end

      def self.get_attendees(event_id)
        result = nil

        sql = "Select * from staging_event_attendees WHERE event_id='#{event_id}'"

        query_result = ActiveRecord::Base.connection.execute(sql)

        if query_result.num_tuples > 0
          result = begin
            JSON.parse(query_result.first['attendees'])
          rescue JSON::ParserError
            []
          end

        end

        {result: result, success: query_result.result_error_message.size == 0}
      end

      def self.save_message_server(messages_thread_id, message_server)
        json_message_server = message_server.to_json

        sql = "INSERT INTO staging_server_messages (messages_thread_id, server_message) VALUES (#{messages_thread_id}, #{ActiveRecord::Base.sanitize(json_message_server)})"

        ActiveRecord::Base.connection.execute(sql)
      end

      def self.get_messages_server(messages_thread_id)
        result = []

        sql = "Select * from staging_server_messages WHERE messages_thread_id=#{messages_thread_id}"

        query_result = ActiveRecord::Base.connection.execute(sql)

        if query_result.num_tuples > 0
          query_result.each do |tuple|
            result << JSON.parse(tuple['server_message'])
          end
        end

        result
      end

      def self.archive_thread(thread_id)
        sql = "Select * from staging_messages_thread_archive_actions WHERE messages_thread_id=#{thread_id}"

        query_result = ActiveRecord::Base.connection.execute(sql)
        if query_result.num_tuples > 0
          id = query_result.first['id']
          sql = "UPDATE staging_messages_thread_archive_actions SET currently_archived=true WHERE id=#{id}"
        else
          sql = "INSERT INTO staging_messages_thread_archive_actions (messages_thread_id, currently_archived) VALUES (#{thread_id}, true)"
        end

        ActiveRecord::Base.connection.execute(sql)
      end

      def self.unarchive_thread(thread_id)
        sql = "Select * from staging_messages_thread_archive_actions WHERE messages_thread_id=#{thread_id}"

        query_result = ActiveRecord::Base.connection.execute(sql)
        if query_result.num_tuples > 0
          id = query_result.first['id']
          sql = "UPDATE staging_messages_thread_archive_actions SET currently_archived=false WHERE id=#{id}"
        else
          sql = "INSERT INTO staging_messages_thread_archive_actions (messages_thread_id, currently_archived) VALUES (#{thread_id}, false)"
        end

        ActiveRecord::Base.connection.execute(sql)
      end

      def self.is_thread_archived?(messages_thread_id)
        sql = "Select * from staging_messages_thread_archive_actions WHERE messages_thread_id=#{messages_thread_id}"
        query_result = ActiveRecord::Base.connection.execute(sql)

        query_result.try(:first).try(:[], 'currently_archived') == 't'
      end

    end
  end
end