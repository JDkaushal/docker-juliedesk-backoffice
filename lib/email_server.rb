module EmailServer

  class MessageDeliveryError < StandardError; end
  class CopyToExistingThreadError < StandardError; end
  class CopyToNewThreadError < StandardError; end
  class CalendarServerNotResponding < StandardError; end

  #API_BASE_PATH = "https://jd-email-server-staging.herokuapp.com/api/v1"
  SERVER_PATH = "#{ENV['EMAIL_SERVER_BASE_PATH']}"
  API_BASE_PATH = "#{ENV['EMAIL_SERVER_BASE_PATH']}/api/v1"

  #API_BASE_PATH = "http://localhost:3000/api/v1"

  def self.list_messages_threads opts={}
    url_params = {
        filter: opts[:filter],
        offset: opts[:offset] || 0,
        limit: opts[:limit] || 10,
        specific_ids: opts[:specific_ids],
        full: opts[:full].present?,
    }

    if opts[:only_version]
      url_params.merge!({only_version: true})
    end

    self.make_request :get, "/messages_threads?#{url_params.to_param}"
  end

  def self.get_messages_thread opts={}
    url = "/messages_threads/#{opts[:server_thread_id]}"
    if opts[:show_split].present?
      url += "&show_split=true"
    end
    result = self.make_request :get, url

    if ENV['STAGING_APP']
      result['messages'] << StagingHelpers::MessagesThreadsHelper.get_messages_server(opts[:messages_thread_id])
      result['messages'].flatten!
    end

    result
  end

  def self.search_messages opts={}
    opts[:limit] ||= 1000
    opts[:labels] ||= ""
    opts[:after] ||= (DateTime.now - 30.days).to_s
    url = "/messages/search?#{opts.to_param}"
    result = self.make_request :get, url

    result
  end

  def self.add_and_remove_labels opts={}
    self.make_request :post,
                      "/messages_threads/update_labels",
                      {
                          messages_thread_ids: opts[:messages_thread_ids],
                          labels_to_add: opts[:labels_to_add],
                          labels_to_remove: opts[:labels_to_remove]
                      }
  end

  def self.deliver_message opts={}
    params = {
        message: {
            subject: opts[:subject],
            from: opts[:from],
            to: opts[:to],
            cc: opts[:cc],
            bcc: opts[:bcc],
            text: opts[:text],
            html: opts[:html],
            quote_replied_message: opts[:quote_replied_message],
            quote_forward_message: opts[:quote_forward_message],
            reply_to_message_id: opts[:reply_to_message_id]
        }
    }

    if ENV['STAGING_APP']
      #params[:message][:reply_to_message_id] = ''
      params[:message][:cc] = ''
      params[:message][:to] = ENV['STAGING_TARGET_EMAIL_ADDRESS']
      params[:message][:subject] = 'Staging: ' + opts[:subject]
    end

    response = self.make_request_raw :post, "/messages/send_message", params

    if response
      if response.status == 200
        res = JSON.parse(response.body)['data']
      else
        raise MessageDeliveryError.new("Can't deliver message: #{JSON.parse(response.body)['message']}")
      end
    else
      raise MessageDeliveryError.new("Can't deliver message: EmailServer error")
    end


    message = res['message']

    if ENV['STAGING_APP']
      cloned_message = message.clone
      puts '*' * 50
      puts message.inspect
      puts '*' * 50
      cloned_message['to'] = opts[:to]
      cloned_message['cc'] = opts[:cc]
      cloned_message['messages_thread_id'] = opts[:server_thread_id]

      StagingHelpers::MessagesThreadsHelper.save_message_server(opts[:message_thread_id], cloned_message)
    end

    message
  end

  def self.copy_message_to_new_thread opts={}
    raise CopyToNewThreadError.new("No message id given") unless opts[:server_message_id]
    copy_options = {}
    if opts[:force_subject]
      copy_options[:force_subject] = opts[:force_subject]
    end

    res = self.make_request :post,
                            "/messages/#{opts[:server_message_id]}/copy_to_new_thread",
                            copy_options
    res
  end

  def self.copy_message_to_existing_thread opts={}
    raise CopyToExistingThreadError.new("No message id given") unless opts[:server_message_id]
    raise CopyToExistingThreadError.new("No thread id given") unless opts[:server_thread_id]


    res = self.make_request :post,
                            "/messages/#{opts[:server_message_id]}/copy_to_existing_thread",
                            {
                                messages_thread_id: opts[:server_thread_id]
                            }
    res
  end

  def self.archive_thread opts={}
    self.add_and_remove_labels({
      messages_thread_ids: [opts[:messages_thread_id]],
      labels_to_add: [],
      labels_to_remove: ["INBOX"]
    })
  end

  def self.unarchive_thread opts={}
    self.add_and_remove_labels({
                                   messages_thread_ids: [opts[:messages_thread_id]],
                                   labels_to_add: ["INBOX"],
                                   labels_to_remove: []
                               })
  end

  def self.split_messages opts={}
    self.make_request :post,
                      "/messages_threads/#{opts[:messages_thread_id]}/split",
                      {
                          message_ids: opts[:message_ids]
                      }
  end

  def self.attachment_inline_path opts={}
    "#{SERVER_PATH}/messages/#{opts[:message]['id']}/get_attachment?attachment_id=#{opts[:attachment]['attachment_id']}&inline=true"
  end

  private
  def self.make_request method, path, post_params={}
    response = self.make_request_raw method, path, post_params

    if response
      response.parse['data']
    else
      nil
    end
  end

  def self.make_request_raw method, path, post_params={}
    http = HTTP.auth(ENV['EMAIL_SERVER_API_KEY'])
    url = "#{API_BASE_PATH}#{path}"

    ssl_context = OpenSSL::SSL::SSLContext.new
    if Rails.env == "development"
      ssl_context.verify_mode = OpenSSL::SSL::VERIFY_NONE
    end

    begin
      response = if method == :get
                  http.get(url, ssl_context: ssl_context)
                 elsif method == :post
                  http.post(url, body: post_params.to_param, ssl_context: ssl_context)
                 end
    rescue HTTP::ConnectionError => e
      raise CalendarServerNotResponding.new(e.message)
    end

    response
  end
end