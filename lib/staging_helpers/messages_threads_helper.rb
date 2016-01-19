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
        result = JSON.parse(query_result.first['attendees'])
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

  end
end