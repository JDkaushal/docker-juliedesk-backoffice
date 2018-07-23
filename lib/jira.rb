class Jira

  API_VERSION         = 2
  TASK_ISSUE          = ENV['JIRA_TASK_ISSUE_ID']
  DEFAULT_ASSIGNEE    = ENV['JIRA_DEFAULT_ASSIGNEE']
  API_ISSUE_PATH      = 'issue'
  SEARCH_PATH        = 'search'

  class DuplicateTicket < StandardError ; end

  def initialize(params)
    @api_url      = params.fetch(:api_url)
    @api_user     = params.fetch(:api_user)
    @api_key      = params.fetch(:api_key)
    @api_version  = params.fetch(:api_version) || API_VERSION
    @project_id   = params.fetch(:project_id)
  end

  def create_ticket(issue_type, data)
    raise DuplicateTicket.new("This is ticket already exist") if self.duplicate?(data)
    send_request(API_ISSUE_PATH, ticket_data(issue_type, data))
  end
  
  def duplicate?(data)
    summary = data.fetch(:summary)
    jql =  "summary ~ \"#{summary}\" AND status != \"Done\""

    search_data = {
        "jql": jql,
        "startAt": 0,
        "maxResults": 1,
        "fields": ["summary"],
        "fieldsByKeys": false
    }
    response = send_request(SEARCH_PATH, search_data)
    response.body["total"] > 0
  end

  private

  def ticket_data(issue_type, data)
    summary     = data.fetch(:summary)
    labels      = data.fetch(:labels, [])
    description = data.fetch(:description)
    assignee    = data.fetch(:assignee, DEFAULT_ASSIGNEE)

    {
        "fields": {
            "project":     { "id": @project_id },
            "issuetype":   { "id": issue_type || TASK_ISSUE },
            "summary":     summary,
            "labels":      labels,
            "description": description,
            "assignee":     { "name": assignee }
        }
    }
  end

  def generate_api_url(path)
    URI.parse("#{@api_url}/#{@api_version}/#{path}")
  end

  def send_request(path, data)
    uri    = generate_api_url(path)

    request = Net::HTTP::Post.new(uri)
    request.basic_auth(@api_user, @api_key)
    request.content_type = "application/json"
    request["Accept"] = "application/json"
    request.body = JSON.dump(data)

    req_options = { use_ssl: uri.scheme == "https" }

    response = Net::HTTP.start(uri.hostname, uri.port, req_options) do |http|
      http.request(request)
    end

    OpenStruct.new({ code: response.code, body: JSON.parse(response.body) })
  end

end