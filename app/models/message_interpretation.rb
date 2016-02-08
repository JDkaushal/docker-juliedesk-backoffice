class MessageInterpretation < ActiveRecord::Base

  belongs_to :message

  QUESTION_MAIN = "main"
  QUESTION_ENTITIES = "entities"

  def self.questions
    [QUESTION_MAIN, QUESTION_ENTITIES]
  end

  def process
    client = HTTPClient.new
    client.ssl_config.verify_mode = 0
    url = "#{ENV['CONSCIENCE_API_BASE_PATH']}/#{self.question}/?id=#{self.message.server_message_id}&token=#{ENV['CONSCIENCE_API_KEY']}"
    response = client.get(url)
    self.update_attribute :raw_response, response.body
  end
end