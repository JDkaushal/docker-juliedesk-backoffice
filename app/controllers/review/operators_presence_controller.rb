class Review::OperatorsPresenceController < ReviewController

  skip_before_filter :verify_authenticity_token
  skip_before_filter :only_super_operator_level_2_or_admin
  before_filter :only_planning_access

  def index

    respond_to do |format|
      format.html {
        if params[:start]
          @operators = Operator.where(privilege: [Operator::PRIVILEGE_OPERATOR, Operator::PRIVILEGE_SUPER_OPERATOR_LEVEL_1, Operator::PRIVILEGE_SUPER_OPERATOR_LEVEL_2], active: true).includes(:operator_presences).sort_by{|o| [o.level, o.name]}
          render "index.csv"
          return
        end
      }
      format.json {
        render json: {
          status: "success",
          data: {
              operators: generate_operators_presence_data(DateTime.parse(params[:start]))
          }
        }
      }

      format.csv {
        @operators = Operator.where(privilege: [Operator::PRIVILEGE_OPERATOR, Operator::PRIVILEGE_SUPER_OPERATOR_LEVEL_1, Operator::PRIVILEGE_SUPER_OPERATOR_LEVEL_2], active: true).sort_by{|o| [o.level, o.name]}
        @operator_presences = OperatorPresence.where(operator_id: @operators.map(&:id)).where("date > ? AND date < ?", DateTime.parse(params[:start]) - 2.days, DateTime.parse(params[:start]) + 9.days)
      }
    end
  end

  def forecast

    unless params[:start]
      params[:start] = DateTime.now.beginning_of_week.to_s
    end

    date = DateTime.parse params[:start]

    # http = HTTP.auth(ENV['CONSCIENCE_API_KEY'])
    # url = "#{ENV['CONSCIENCE_API_BASE_PATH_V1']}/planning/?date=#{date.strftime('%Y-%m-%d')}"
    #
    # response = http.get(url)
    json_response = AiProxy.new.build_request(:fetch_forecast, { date: date.strftime('%Y-%m-%d')})['planning']


    # client = HTTPClient.new(default_header: {
    #                             "Authorization" => ENV['CONSCIENCE_API_KEY']
    #                         })
    # client.ssl_config.verify_mode = 0
    #
    # response = client.get(url)

    #json_response = JSON.parse(response.body)['planning']
    #json_response = response.parse['planning']

    @operators = json_response.map do |name, data|
      o = Operator.new(name: name)
      first_date = date.in_time_zone("Indian/Antananarivo").change(hour: 6)
      o.operator_presences = data.flatten.map.with_index{|bit, i|
        bit == 1 ? OperatorPresence.new(date: first_date + (i * 30.minutes)) : nil
      }.compact

      o
    end

  end

  def add
    OperatorPresence.where(operator_id: params[:operator_id]).where(date: params[:presences].map{|p| DateTime.parse(p)}).delete_all
    params[:presences].map{|p| DateTime.parse(p)}.each do |p|
      OperatorPresence.create operator_id: params[:operator_id], date: p, is_review: params[:is_review].present?
    end

    render json: {}
  end

  def copy_day
    raise "no day given" unless params[:day]
    OperatorPresence.where("date >= ? AND date < ?", DateTime.parse(params[:day]), DateTime.parse(params[:day]) + 1.day).to_a.each do |opp|
      new_date = opp.date + params[:days].to_i.days
      existing_presence = OperatorPresence.find_by(date: new_date, operator_id: opp.operator_id)
      OperatorPresence.create date: new_date, operator_id: opp.operator_id unless existing_presence.present?
    end

    render json: {}
  end

  def reset_day
    raise "no day given" unless params[:day]
    OperatorPresence.where("date >= ? AND date < ?", DateTime.parse(params[:day]), DateTime.parse(params[:day]) + 1.day).delete_all

    render json: {}
  end

  def remove
    OperatorPresence.where(operator_id: params[:operator_id]).where(date: params[:presences].map{|p| DateTime.parse(p)}, is_review: params[:is_review].present?).delete_all

    render json: {}
  end

  def upload_planning_constraints
    result = ''

    if params[:file].present?
      filename = "planning_constraints_#{Time.now.strftime('%d-%m-%YT%H:%M:%S')}.csv"

      Uploaders::AmazonAws.store_file(filename, params[:file])

      result = AiProxy.new.build_request(:initiate_planning, { productivity: params[:productivity], filename: filename, date: params[:start_date] })

      result.merge!('start_date' => params[:start_date])
      handle_planning_ai_data(result)
    end

    render json: result.merge(filename: filename)
  end

  def get_planning_from_ai

    result = AiProxy.new.build_request(:fetch_planning, { date: params[:start_date], filename: params[:filename], productivity: params[:productivity] })
    result.merge!('start_date' => params[:start_date])
    handle_planning_ai_data(result)

    render json: result
  end

  private

  def generate_operators_presence_data(start)
    operators = Operator.where(privilege: [Operator::PRIVILEGE_OPERATOR, Operator::PRIVILEGE_SUPER_OPERATOR_LEVEL_1, Operator::PRIVILEGE_SUPER_OPERATOR_LEVEL_2], active: true)
    operator_presences = OperatorPresence.where(operator_id: operators.map(&:id)).where("date >= ? AND date < ?", start, start + 7.days)

    operators.sort_by{|o| [o.level, o.name]}.map{|o|
      presences = operator_presences.select{|op| op.operator_id == o.id}
      {
          name: o.name,
          id: o.id,
          stars: o.stars,
          privilege: o.privilege,
          in_formation: o.in_formation,
          color: o.color,
          presences: presences.select{|p| p.is_review == false}.map{|op| op.date.strftime("%Y%m%dT%H%M00")},
          review_presences: presences.select{|p| p.is_review == false}.map{|op| op.date.strftime("%Y%m%dT%H%M00")}
      }
    }
  end

  def clean_operator_presences_for_week(start_date)
    Operator.where(privilege: [Operator::PRIVILEGE_OPERATOR, Operator::PRIVILEGE_SUPER_OPERATOR_LEVEL_1, Operator::PRIVILEGE_SUPER_OPERATOR_LEVEL_2], active: true).includes(:operator_presences).each do |operator|
      operator.operator_presences.where("date >= ? AND date < ?", start_date, start_date + 7.days).delete_all
    end
  end

  def handle_planning_ai_data(data)
    # Update the productivity with one used to by the AI to generate the planning
    MySettings['planning.operator_hourly_productivity'] = data['productivity']

    # Update or create the emails forecast for the given period
    data['forecast'] = AiEmailFlowForecast.handle_forecast_data(data['forecast'])

    # Handle the new planning data
    data['planning'] = handle_new_planning_data(data['start_date'], data['planning'])
  end

  def handle_new_planning_data(start_date, data)
    # We begin at 6AM in Madagascar which is the same as 3AM UTC
    start_date = ActiveSupport::TimeZone.new('UTC').parse(start_date).change(hour: 3)
    presences_to_insert = []

    clean_operator_presences_for_week(start_date)

    data.each do |operator_id, presence_days|
      presence_days.each_with_index do |presences, day_nb|
        current_date = start_date + day_nb.days

        presences.each do |presence|
          if presence == 1
            presences_to_insert << "(#{operator_id}, '#{current_date}')"
            #OperatorPresence.create(operator_id: operator_id, date: current_date)
          end

          current_date += 30.minutes
        end
      end
    end

    if presences_to_insert.size > 0
      # We use raw sql to make the bulk insertions, it speeds things up to 70x
      sql = "INSERT INTO operator_presences (\"operator_id\", \"date\") VALUES #{presences_to_insert.join(", ")}"

      ActiveRecord::Base.connection.execute(sql)
    end

    # We generate the newly added presences
    generate_operators_presence_data(start_date)
  end

  def only_planning_access
    if session[:planning_access]
      true
    else
      redirect_to "/"
      false
    end
  end
end