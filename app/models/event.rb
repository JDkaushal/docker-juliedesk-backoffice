class Event < ActiveRecord::Base

  require 'net/http'

  def self.import_events

    print "Fetching active accounts emails...\n"
    emails = Account.get_active_account_emails
    print "Done.\n"

    emails.each do |email|
      print "Fetching #{email} upcoming events...\n"
      events = self.get_upcoming_events_for_email(email)
      print "  #{events.length} events imported.\n"
      events.each do |event|
        if Event.where(email: email, event_id: event['event_id']).empty?
          Event.create email: email, event_id: event['event_id'], calendar_nature: event['calendar_nature'], calendar_id: event['calendar_id']
        end
      end
    end
  end

  def self.get_upcoming_events_for_email email
    t = Time.now
    url = URI.parse("https://#{ApplicationHelper::JD_APP_HOST}/api/v1/upcoming_events?email=#{email}&access_key=gho67FBDJKdbhfj890oPm56VUdfhq8")
    req = Net::HTTP::Get.new(url.to_s)
    res = Net::HTTP.start(url.host, url.port, use_ssl: true) {|http|
      http.request(req)
    }

    if res.code == "200"
      data = JSON.parse(res.body)
      if data['status'] == "success"
        print "Done (#{((Time.now - t)*100).floor/100.0}s)"
        data['data']
      else
        print "Retrying...(#{((Time.now - t)*100).floor/100.0}s)\n"
        self.get_upcoming_events_for_email email
      end
    else
      print "Server error (#{((Time.now - t)*100).floor/100.0}s)"
      []
    end
  end

  def fetch
    url = URI.parse("https://#{ApplicationHelper::JD_APP_HOST}/api/v1/show_event?email=#{email}&event_id=#{event_id}&calendar_id=#{calendar_id}&access_key=gho67FBDJKdbhfj890oPm56VUdfhq8")
    req = Net::HTTP::Get.new(url.to_s)
    res = Net::HTTP.start(url.host, url.port, use_ssl: true) {|http|
      http.request(req)
    }

    data = JSON.parse(res.body)
    data['data']
  end
end