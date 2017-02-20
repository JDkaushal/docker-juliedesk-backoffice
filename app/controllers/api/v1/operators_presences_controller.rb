class Api::V1::OperatorsPresencesController < Api::ApiV1Controller

  def operators_count_at_time
    operators_count_at_time_data = DashboardDataGenerator.generate_operators_count_at_time_data

    render json: {
        status: "success",
        data: operators_count_at_time_data
    }
  end
end