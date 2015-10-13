class Api::V1::OperatorsPresencesController < Api::ApiV1Controller

  def operators_count_at_time
    if params[:date]
      date = DateTime.parse(params[:date])
    else
      date = DateTime.now
    end
    date = date.beginning_of_hour

    operator_presences = OperatorPresence.where(date: date).includes(:operator)
    render json: {
        status: "success",
        data: {
            operators_count: operator_presences.count,
            operators: operator_presences.map{|op|
              {
                  name: op.operator.name,
                  operator_id: op.operator_id
              }
            }
        }
    }
  end
end