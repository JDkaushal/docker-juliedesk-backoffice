class WebhooksController < ApplicationController
  skip_before_action :authenticate, :set_locale
  protect_from_forgery except: :new_email

  def new_email
    Rails.logger.info "Incoming Webhooks: new_email"
    # updated_messages_thread_ids = Message.import_emails(true)
    # WebSockets::Manager.trigger_new_email(updated_messages_thread_ids)

    ImportEmailsWorker.enqueue

    # if ENV['PUSHER_APP_ID']
    #   Pusher.trigger('private-global-chat', 'new-email', {
    #       :message => 'new_email',
    #       :messages_threads_count => MessagesThread.items_to_classify_count,
    #       :updated_messages_thread_ids => updated_messages_thread_ids
    #   })
    # elsif ENV['RED_SOCK_URL']
    #   RedSock.trigger 'private-global-chat', 'new-email', {
    #                                            :message => 'new_email',
    #                                            :messages_threads_count => MessagesThread.items_to_classify_count,
    #                                            :updated_messages_thread_ids => updated_messages_thread_ids
    #                                        }
    # end
    render json: {
        status: "success",
        message: "",
        data: {

        }
    }
  end
end
