class WebhooksController < ApplicationController
  skip_before_filter :authenticate, :set_locale
  protect_from_forgery except: :new_email

  def new_email
    events = JSON.parse params[:mandrill_events]

    #Gmail::Message.new({text: "New email", to: "elrandil@gmail.com"}).deliver
    updated_messages_thread_ids = Message.import_emails
    Pusher.trigger('private-global-chat', 'new-email', {
        :message => 'new_email',
        :messages_threads_count => MessagesThread.items_to_classify_count,
        :updated_messages_thread_ids => updated_messages_thread_ids
    })

    render json: {
        status: "success",
        message: "",
        data: {

        }
    }
  end
end
