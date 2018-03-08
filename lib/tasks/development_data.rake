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

  def random_string length
    (0...length).map { ('a'..'z').to_a[rand(26)] }.join
  end
end