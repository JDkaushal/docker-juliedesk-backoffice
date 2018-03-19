namespace :development_data do
  logger = Logger.new(STDOUT)
  logger.level = Logger::INFO
  Rails.logger = logger

  task :init => :environment do |t|
    raise 'Are you fool?' unless Rails.env == 'development'

    MessagesThread.delete_all
    Message.delete_all
    MessageClassification.delete_all
    JulieAction.delete_all

    JulieAlias.delete_all

    JulieAlias.create({
                          email: 'julie@juliedesk.com',
                          name: 'Julie Desk',
                          footer_fr: '',
                          footer_en: '',
                          signature_fr: '',
                          signature_en: ''
                      })

    Message.import_emails
  end

  def append_message_interpretation message_id = nil
    MessageInterpretation.create(
        message_id: message_id || Message.last.id,
        question: MessageInterpretation::QUESTION_MAIN,
        raw_response: {
              "language_detected": "en",
              "constraints_data": nil,
              "request_confidence": 0.88,
              "request_proba": 0.61,
              "asap": false,
              "location_data": {
                  "text": nil,
                  "location_nature": nil
              },
              "formal_language": false,
              "request_classif": "ask_date_suggestions",
              "appointment_classif": "call",
              "appointment_confidence": 0.88,
              "client_on_trip": nil,
              "algo_duration": 0,
              "duration": 30,
              "dates_to_check_confidence": 0,
              "dates_to_check": [],
              "appointment_proba": 0.44
        }.to_json)

  end

  def random_string length
    (0...length).map { ('a'..'z').to_a[rand(26)] }.join
  end
end