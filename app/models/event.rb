class Event < ActiveRecord::Base

  #HOST = "juliedesk-release.herokuapp.com"
  HOST = "juliedesk-app.herokuapp.com"
  require 'net/http'

  def self.get_active_account_emails
    url = URI.parse("https://#{HOST}/api/v1/accounts?access_key=gho67FBDJKdbhfj890oPm56VUdfhq8")
    req = Net::HTTP::Get.new(url.to_s)
    res = Net::HTTP.start(url.host, url.port, use_ssl: true) {|http|
      http.request(req)
    }

    data = JSON.parse(res.body)
    data['data']['items'].map{|user| user['email']}
  end

  def self.import_events

    print "Fetching active accounts emails...\n"
    emails = self.get_active_account_emails
    print "Done.\n"

    emails.each do |email|
      print "Fetching #{email} upcomping events...\n"
      events = self.get_upcoming_events_for_email(email)
      p events
      events.each do |event|
        if Event.where(email: email, event_id: event['event_id']).empty?
          Event.create email: email, event_id: event['event_id'], calendar_nature: event['calendar_nature'], calendar_id: event['calendar_id']
        end
      end
    end
  end

  def self.get_upcoming_events_for_email email
    url = URI.parse("https://#{HOST}/api/v1/upcoming_events?email=#{email}&access_key=gho67FBDJKdbhfj890oPm56VUdfhq8")
    req = Net::HTTP::Get.new(url.to_s)
    res = Net::HTTP.start(url.host, url.port, use_ssl: true) {|http|
      http.request(req)
    }

    data = JSON.parse(res.body)
    data['data']
  end

  def fetch
    url = URI.parse("https://#{HOST}/api/v1/show_event?email=#{email}&event_id=#{event_id}&calendar_id=#{calendar_id}&access_key=gho67FBDJKdbhfj890oPm56VUdfhq8")
    req = Net::HTTP::Get.new(url.to_s)
    res = Net::HTTP.start(url.host, url.port, use_ssl: true) {|http|
      http.request(req)
    }

    data = JSON.parse(res.body)
    data['data']
  end

  def self.format_dates start_date_str, end_date_str
    return "" unless start_date_str && end_date_str
    start_time = DateTime.parse start_date_str
    end_time = DateTime.parse end_date_str

    if start_time.to_date == end_time.to_date
      start_time.strftime('%A %d %B %Y') + "<br>" + start_time.strftime('%H:%M') + " - " + end_time.strftime('%H:%M')
    else
      start_time.strftime('%A %d %B %Y, %H:%M') + "<br>" + end_time.strftime('%A %d %B %Y, %H:%M')
    end
  end
end