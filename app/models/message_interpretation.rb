class MessageInterpretation < ActiveRecord::Base

  belongs_to :message

  QUESTION_MAIN = "main"
  QUESTION_ENTITIES = "entities"

  def self.questions
    [QUESTION_MAIN, QUESTION_ENTITIES].freeze
  end

  def process
    if self.question == QUESTION_MAIN
      process_main_entity
    elsif self.question == QUESTION_ENTITIES
      process_entities_entity
    end
  end

  def json_response
    if raw_response
      begin
        JSON.parse(self.raw_response)
      rescue
        {}
      end
    else
      nil
    end
  end

  def self.parallel_run_stats data=nil
    data ||= self.parallel_run_recap

    fields = data.first[:human].keys

    Hash[fields.map do |field|
           support = data.select{|d| %w"correct incorrect unknown".include? d[:comparison][field]}.length
           total_number = data.select{|d| %w"correct incorrect".include? d[:comparison][field]}.length
           precision = total_number > 0 ? data.select{|d| d[:comparison][field] == "correct"}.length * 1.0 / total_number : nil
           recall = total_number * 1.0 / support
           [field, {
                     precision: precision,
                     recall: recall,
                     support: support
                 }]
         end]
  end

  def self.parallel_run_recap
    message_interpretations = MessageInterpretation.where(question: MessageInterpretation::QUESTION_MAIN).select(:message_id, :raw_response, :question)

    message_ids = message_interpretations.map(&:message_id).uniq

    message_classifications = MessageClassification.where(message_id: message_ids).select(:message_id, :classification, :updated_at, :appointment_nature, :locale)

    messages = Message.select(:id, :messages_thread_id).where(id: message_ids)

    data = message_ids.map do |message_id|
      mc = message_classifications.select{|mc| mc.message_id == message_id}.sort_by(&:updated_at).last
      message_interpretation = message_interpretations.select{|mc| mc.message_id == message_id}.last

      if mc && message_interpretation.raw_response
        ai_response = message_interpretation.json_response
        {
            message_id: message_id,
            messages_thread_id: messages.select{|m| m.id == message_id}.first.messages_thread_id,
            ai: {
                classification: ai_response['request_classif'],
                appointment: ai_response['appointment_classif'],
                locale: ai_response['language_detected'],
            },
            human: {
                classification: mc.classification,
                appointment: mc.appointment_nature,
                locale: mc.locale
            },
        }
      else
        nil
      end
    end.compact

    data.map do |d|
      classification_correct = if d[:ai][:classification] != "unknown"
                                 if d[:ai][:classification] == d[:human][:classification]
                                   "correct"
                                 else
                                   "incorrect"
                                 end
                               else
                                 "unknown"
                               end
      appointment_correct = if d[:human][:appointment]
                              if d[:ai][:appointment] != "unknown"
                                if d[:ai][:appointment] == d[:human][:appointment]
                                  "correct"
                                else
                                  "incorrect"
                                end
                              else
                                "unknown"
                              end
                            else
                              "not_tagged_by_human"
                            end

      locale_correct = appointment_correct = if d[:human][:locale]
                                               if d[:ai][:locale] == d[:human][:locale]
                                                 "correct"
                                               else
                                                 "incorrect"
                                               end
                                             else
                                               "not_tagged_by_human"
                                             end

      d.merge({
                  comparison: {
                      classification: classification_correct,
                      appointment: appointment_correct,
                      locale: locale_correct
                  }
              })
    end

  end

  private


  def process_main_entity
    # http = HTTP.auth(ENV['CONSCIENCE_API_KEY'])
    # url = "#{ENV['CONSCIENCE_API_BASE_PATH_V1']}/main/?id=#{self.message.server_message_id}"
    #
    # response = http.get(url)

    response_body = AiProxy.new(format_response: false).build_request(:process_entity_main, {id: self.message.server_message_id}).body

    response_body_str = ''

    continue = true
    while continue
      current_chunk = response_body.readpartial
      if current_chunk.present?
        response_body_str += current_chunk
      else
        continue = false
      end
    end

    # client = HTTPClient.new(default_header: {
    #                             "Authorization" => ENV['CONSCIENCE_API_KEY']
    #                         })
    # client.ssl_config.verify_mode = 0
    # url = "#{ENV['CONSCIENCE_API_BASE_PATH_V1']}/main/?id=#{self.message.server_message_id}"
    # response = client.get(url)
    self.raw_response = response_body_str
    begin
      JSON.parse(self.raw_response)
      #response.parse
      self.error = false
    rescue
      self.error = true
    end

    self.save
  end

  def process_entities_entity
    mess = self.message
    thread = mess.messages_thread

    messages = thread.re_import

    server_message = messages.find{|m| m.id == mess.id}.try(:server_message)

    if server_message.present?

      body = {
          'parsed_html' => server_message['parsed_html'],
          'text' => server_message['text'],
          'sender' => server_message['from'],
          'date' => server_message['date']
      }

      response_body = AiProxy.new(format_response: false).build_request(:process_entity_entities, body).body

      response_body_str = ''

      continue = true
      while continue
        current_chunk = response_body.readpartial
        if current_chunk.present?
          response_body_str += current_chunk
        else
          continue = false
        end
      end
      # http = HTTP.auth(ENV['CONSCIENCE_API_KEY'])
      # url = "#{ENV['CONSCIENCE_API_BASE_PATH_V2']}/#{self.question}/"
      #
      #
      #
      # response = http.post(url, json: body)

      # client = HTTPClient.new(default_header: {
      #                             "Authorization" => ENV['CONSCIENCE_API_KEY']
      #                         })
      #
      # client.ssl_config.verify_mode = 0
      # url = "#{ENV['CONSCIENCE_API_BASE_PATH_V2']}/#{self.question}/"

      # body = {
      #     'parsed_html' => server_message['parsed_html'],
      #     'text' => server_message['text'],
      #     'sender' => server_message['from'],
      #     'date' => server_message['date']
      # }.to_json

      #response = client.post(url, body)

      self.raw_response = response_body_str
      begin
        JSON.parse(self.raw_response)
        #response.parse
        self.error = false
      rescue
        self.error = true
      end

      self.save
    end
  end
end