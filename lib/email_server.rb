module EmailServer

  #API_BASE_PATH = "https://jd-email-server-staging.herokuapp.com/api/v1"
  SERVER_PATH = "https://jd-email-server.herokuapp.com"
  API_BASE_PATH = "https://jd-email-server.herokuapp.com/api/v1"

  #API_BASE_PATH = "http://localhost:3000/api/v1"
  API_ACCESS_KEY = "wpyrynfrgbtphqhhufqeobnmzulcvczscfidsnwfkljfgwpseh"

  def self.list_messages_threads opts={}
    url_params = {
        filter: opts[:filter] || "INBOX",
        offset: opts[:offset] || 0,
        limit: opts[:limit] || 10,
        full: opts[:full].present?,
        access_key: API_ACCESS_KEY
    }

    self.make_request :get, "/messages_threads?#{url_params.to_param}"

  end

  def self.get_messages_thread opts={}
    self.make_request :get,
                      "/messages_threads/#{opts[:messages_thread_id]}?access_key=wpyrynfrgbtphqhhufqeobnmzulcvczscfidsnwfkljfgwpseh"
  end

  def self.add_and_remove_labels opts={}
    self.make_request :post,
                      "/messages_threads/update_labels?access_key=wpyrynfrgbtphqhhufqeobnmzulcvczscfidsnwfkljfgwpseh",
                      {
                          messages_thread_ids: opts[:messages_thread_ids],
                          labels_to_add: opts[:labels_to_add],
                          labels_to_remove: opts[:labels_to_remove]
                      }
  end

  def self.deliver_message opts={}
    res = self.make_request :post,
                      "/messages/send_message?access_key=wpyrynfrgbtphqhhufqeobnmzulcvczscfidsnwfkljfgwpseh",
                      {
                          message: {
                            subject: opts[:subject],
                            from: opts[:from],
                            to: opts[:to],
                            cc: opts[:cc],
                            text: opts[:text],
                            html: opts[:html],
                            quote_replied_message: opts[:quote],
                            reply_to_message_id: opts[:reply_to_message_id]
                        }
                      }

    res['message']
  end

  def self.copy_message_to_new_thread opts={}
    raise "No message id given" unless opts[:server_message_id]
    copy_options = {}
    if opts[:force_subject]
      copy_options[:force_subject] = opts[:force_subject]
    end

    res = self.make_request :post,
                            "/messages/#{opts[:server_message_id]}/copy_to_new_thread?access_key=wpyrynfrgbtphqhhufqeobnmzulcvczscfidsnwfkljfgwpseh",
                            copy_options
    res
  end

  def self.copy_message_to_existing_thread opts={}
    raise "No message id given" unless opts[:server_message_id]
    raise "No thread id given" unless opts[:server_thread_id]


    res = self.make_request :post,
                            "/messages/#{opts[:server_message_id]}/copy_to_existing_thread?access_key=wpyrynfrgbtphqhhufqeobnmzulcvczscfidsnwfkljfgwpseh",
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
                      "/messages_threads/#{opts[:messages_thread_id]}/split?access_key=wpyrynfrgbtphqhhufqeobnmzulcvczscfidsnwfkljfgwpseh",
                      {
                          message_ids: opts[:message_ids]
                      }
  end

  def self.attachment_inline_path opts={}
    "#{SERVER_PATH}/messages/#{opts[:message]['id']}/get_attachment?attachment_id=#{opts[:attachment]['attachment_id']}&inline=true"
  end

  private
  def self.make_request method, path, post_params={}
    client = HTTPClient.new

    url = "#{API_BASE_PATH}#{path}"
    if method == :get
      response = client.get(url)
    elsif method == :post
      response = client.post(url, post_params.to_param)
    end

    if response
      JSON.parse(response.body)['data']
    else
      nil
    end
  end
end