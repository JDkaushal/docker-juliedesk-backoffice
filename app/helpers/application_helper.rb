module ApplicationHelper


  def self.hash_from_parenthesized_contact contact
    {
        email: contact.split(" ").last.gsub("(", "").gsub(")", ""),
        name: self.strip_contact_name(contact)
    }
  end
  def self.strip_email contact
    begin
      Mail::AddressList.new(contact.to_ascii).addresses.first.address
    rescue
      nil
    end
  end

  def self.strip_contact_name contact
    email_parts = contact.split(" ")
    email_parts.pop
    email_parts.join(" ")
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

  def display_duration duration_in_seconds
    duration_in_seconds = duration_in_seconds.to_i
    hours = (duration_in_seconds/60)/60
    minutes = (duration_in_seconds/60)%60
    seconds = duration_in_seconds%60

    "#{(hours > 0)?"#{hours}h ":nil}#{minutes}' #{(seconds < 10)?"0#{seconds}":seconds}''"
  end
end
