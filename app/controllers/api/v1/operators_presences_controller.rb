class Api::V1::OperatorsPresencesController < Api::ApiV1Controller

  def operators_count_at_time
    if params[:date]
      date = DateTime.parse(params[:date])
    else
      date = DateTime.now
    end

    # Set to closest half-hour
    date = date.change(min: (date.min / 30) * 30)

    operator_presences = OperatorPresence.where(date: date, is_review: false).includes(:operator)

    if ENV['PUSHER_APP_ID']
      pusher_user_emails = Pusher.get("/channels/presence-global/users")[:users].map{|u| u['id']}
    elsif ENV['RED_SOCK_URL']
      pusher_user_emails = RedSock.get_channel_info("presence-global").map{|u| u['email']}
    else
      pusher_user_emails = []
    end
    render json: {
        status: "success",
        data: {
            operators_count: operator_presences.count,
            operators: operator_presences.map{|op|
              {
                  name: op.operator.name,
                  email: op.operator.email,
                  privilege: op.operator.privilege,
                  operator_of_the_month: op.operator.operator_of_the_month,
                  present: pusher_user_emails.include?(op.operator.email),
                  operator_id: op.operator_id
              }
            }
        }
    }
  end
end