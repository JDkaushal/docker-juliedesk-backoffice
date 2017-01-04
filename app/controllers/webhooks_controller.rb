class WebhooksController < ApplicationController
  skip_before_filter :authenticate, :set_locale
  protect_from_forgery except: :new_email

  def new_email
    updated_messages_thread_ids = Message.import_emails(true)
    if ENV['PUSHER_APP_ID']
      Pusher.trigger('private-global-chat', 'new-email', {
          :message => 'new_email',
          :messages_threads_count => MessagesThread.items_to_classify_count,
          :updated_messages_thread_ids => updated_messages_thread_ids
      })
    elsif ENV['RED_SOCK_URL']
      RedSock.trigger 'private-global-chat', 'new-email', {
                                               :message => 'new_email',
                                               :messages_threads_count => MessagesThread.items_to_classify_count,
                                               :updated_messages_thread_ids => updated_messages_thread_ids
                                           }
    end

    render json: {
        status: "success",
        message: "",
        data: {

        }
    }
  end
end
