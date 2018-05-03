def fetch_issues
  client = Jira.new(TicketService.jira_options)
  issues = nil
  response = nil
  startAt = 0
  while issues == nil || response['total'] - response['startAt'] - response['issues'].length > 0
    response = client.send(:send_request, 'search', {
        "jql": "created > -30d",
        "startAt": startAt,
        "maxResults": 100,
        "fields": ["labels"],
        "fieldsByKeys": false
    }).body
    startAt += 100
    issues = (issues || []) + response['issues']
  end
  issues
end

def top_tek_tags
  issues = fetch_issues
  issues.map{|issue| issue['fields']['labels']}.flatten.select{|label| label.include? "tek_"}.group_by{|k| k}.map{|k, v| [k, v.length]}.sort_by{|a| -a[1]}.first(20).each do |label|
    puts "#{label[0]}: #{label[1]} (#{(label[1] * 100.0 / issues.length).round(2)}%)"
  end
  nil
end
