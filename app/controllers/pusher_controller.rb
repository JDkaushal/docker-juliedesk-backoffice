class PusherController < ApplicationController
  protect_from_forgery :except => [:auth, :webhooks] # stop rails CSRF protection for this action

  skip_before_action :verify_authenticity_token, only: :webhooks
  skip_before_action :authenticate, only: :webhooks
  skip_before_action :set_locale, only: :webhooks

  def auth
    if session[:user_name]
      response = Pusher[params[:channel_name]].authenticate(params[:socket_id], {
          :user_id => session[:user_username], # => required
          :user_info => { # => optional - for example
                          :name => session[:user_name],
                          :email => session[:user_username]
          }
      })


      regexp = Regexp.new "presence-thread-([0-9]*)"
      result = regexp.match(params[:channel_name])

      if result && result.length > 1
        messages_thread_id = result[1]
        messages_thread = MessagesThread.find(messages_thread_id)
        operator = Operator.find_by_email(session[:user_username])
        if messages_thread.locked_by_operator_id.nil?
          locked_at = DateTime.now
          messages_thread.update_attributes locked_by_operator_id: operator.id,
                                            locked_at: locked_at

          OperatorAction.create_and_verify({
                                               initiated_at: locked_at,
                                               target: messages_thread,
                                               nature: OperatorAction::NATURE_LOCK,
                                               operator_id: session[:operator_id],
                                               messages_thread_id: messages_thread.id
                                           })

          send_lock_changed
        elsif messages_thread.locked_by_operator_id == operator.id
          messages_thread.update_attributes locked_at: DateTime.now
        else
          render json: {
              message: "Already locked by another operator",
              data: {
                  locked_by_operator_id: messages_thread.locked_by_operator_id
              }
          }, :status => '403'
          return
        end

      end
      render json: response
    else
      render :text => "Forbidden", :status => '403'
    end
  end

  def webhooks
    if params[:events].length > 0
      event = params[:events][0]
      regexp = Regexp.new "presence-thread-([0-9]*)"
      result = regexp.match(event[:channel])

      if result && result.length > 1
        operator_email = event[:user_id]
        operator = Operator.find_by_email operator_email
        messages_thread_id = result[1]
        messages_thread = MessagesThread.find messages_thread_id

        if event[:name] == "member_removed"

          if messages_thread.locked_by_operator_id == operator.id &&
              (messages_thread.locked_at.nil? || Time.at(params[:time_ms]/1000).to_datetime > messages_thread.locked_at + 1.second)

            messages_thread.update_attribute :locked_by_operator_id, nil

            OperatorAction.create_and_verify({
                                                 initiated_at: Time.at(params[:time_ms]/1000).to_datetime,
                                                 target: messages_thread,
                                                 nature: OperatorAction::NATURE_UNLOCK,
                                                 operator_id: operator.id,
                                                 messages_thread_id: messages_thread.id
                                             })

            send_lock_changed
          end
        elsif event[:name] == "member_added"
          messages_thread.update_attributes locked_by_operator_id: operator.id,
                                            locked_at: DateTime.now

          send_lock_changed
        end
      end
    end

    render nothing: true
  end

  private

  def send_lock_changed
    WebSockets::Manager.trigger_locks_changed

    # if !Rails.env.development? && ENV['PUSHER_APP_ID']
    #   Pusher.trigger('private-global-chat', 'locks-changed', {
    #       :message => 'locks_changed',
    #       :locks_statuses => MessagesThread.get_locks_statuses_hash
    #   })
    # elsif ENV['RED_SOCK_URL']
    #   RedSock.trigger('private-global-chat', 'locks-changed', {
    #                                            :message => 'locks_changed',
    #                                            :locks_statuses => MessagesThread.get_locks_statuses_hash
    #                                        })
    # end
  end
end