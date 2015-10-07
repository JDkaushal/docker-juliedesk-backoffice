class Api::V1::OperatorsPresencesController < Api::ApiV1Controller

  def operators_count_at_time
    if params[:date]
      date = DateTime.parse(params[:date])
    else
      date = DateTime.now
    end
    date = date.beginning_of_hour
    render json: {
        status: "success",
        data: {
            operators_count: OperatorPresence.where(date: date).count
        }
    }
  end
end