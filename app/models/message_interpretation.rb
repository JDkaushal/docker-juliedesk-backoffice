class MessageInterpretation < ActiveRecord::Base

  belongs_to :message

  QUESTION_MAIN = "main"
  QUESTION_ENTITIES = "entities"

  def self.questions
    [QUESTION_MAIN, QUESTION_ENTITIES].freeze
  end

  def process(options = {})
    if self.question == QUESTION_MAIN
      main_entity_options = options.slice(:full_ai_mode)
      process_main_entity(main_entity_options)
    elsif self.question == QUESTION_ENTITIES
      process_entities_entity
    end
  end

  def process!
    message_interpretation = process
    message_interpretation.save
  end

  def client_on_trip
    data = JSON.parse(self.raw_response || "{}")['client_on_trip'] rescue nil
    data.merge!('from_ai' => true) if data.present?
    data
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


  def process_main_entity!
    process_main_entity
    self.save
  end

  def get_main_entity(options = {})
    full_ai_mode = options.fetch(:full_ai_mode, false)
    params = { id: self.message.server_message_id }
    params.merge!(full_ai_mode: true) if full_ai_mode == true

    response_body = DelegatedAiProxyInterface.new(AiProxy.new(format_response: false)).build_request(:process_entity_main, params).body
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

    response_body_str
  end

  def get_entities_entity(params)
    response_body = DelegatedAiProxyInterface.new(AiProxy.new(format_response: false)).build_request(:process_entity_entities, params).body

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

    response_body_str
  end

  def process_main_entity(options = {})
    self.raw_response = get_main_entity(options)
    begin
      JSON.parse(self.raw_response)
      self
      self.error = false
    rescue
      self.error = true
    end
  end

  def process_entities_entity!
    process_entities_entity
    self.save
  end

  def process_entities_entity
    mess = self.message
    thread = mess.messages_thread

    messages = thread.re_import
    server_message = messages.find{|m| m.id == mess.id}.try(:server_message)

    if server_message.present?
      body = {
          'id' => mess.server_message_id,
          'parsed_html' => server_message['parsed_html'],
          'text' => server_message['text'],
          'sender' => server_message['from'],
          'date' => server_message['date'],
          'messages_count' => messages.size
      }

      self.raw_response = get_entities_entity(body)
      begin
        JSON.parse(self.raw_response)
        self.error = false
      rescue
        self.error = true
      end

      self
    end
  end
end