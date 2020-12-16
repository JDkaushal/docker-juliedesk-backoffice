class AdminMailer < ActionMailer::Base
  default from: "Julie <julie@juliedesk.com>"
  def send_csv csv
    attachments['thread_data.csv'] = {mime_type: 'text/csv', content: csv}
    mail(to: 'kaushal@juliedesk.com', subject: "Message Thread created on #{Date.yesterday}", body: 'PFA CSV')
  end
end