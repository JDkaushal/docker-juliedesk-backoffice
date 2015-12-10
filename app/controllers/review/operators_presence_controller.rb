class Review::OperatorsPresenceController < ReviewController

  skip_before_filter :verify_authenticity_token
  before_filter :only_admin

  def index
    respond_to do |format|
      format.html {
        if params[:start]
          @operators = Operator.where(privilege: [Operator::PRIVILEGE_OPERATOR, Operator::PRIVILEGE_SUPER_OPERATOR_LEVEL_1, Operator::PRIVILEGE_SUPER_OPERATOR_LEVEL_2], active: true).includes(:operator_presences)
          render "index.csv"
          return
        end
      }
      format.json {
        render json: {
            status: "success",
            data: {
                operators: Operator.where(privilege: [Operator::PRIVILEGE_OPERATOR, Operator::PRIVILEGE_SUPER_OPERATOR_LEVEL_1, Operator::PRIVILEGE_SUPER_OPERATOR_LEVEL_2], active: true).includes(:operator_presences).sort_by(&:name).sort_by(&:level).map{|o|
                  {
                      name: o.name,
                      id: o.id,
                      stars: o.stars,
                      presences: o.operator_presences.where("date >= ? AND date < ?", DateTime.parse(params[:start]), DateTime.parse(params[:start]) + 7.days).map{|op| op.date.strftime("%Y%m%dT%H%M00")}
                  }
                }
            }
        }
      }
      format.csv {
        @operators = Operator.where(privilege: [Operator::PRIVILEGE_OPERATOR, Operator::PRIVILEGE_SUPER_OPERATOR_LEVEL_1, Operator::PRIVILEGE_SUPER_OPERATOR_LEVEL_2], active: true).includes(:operator_presences).sort_by(&:name).sort_by(&:level)
      }
    end
  end

  def add
    OperatorPresence.where(operator_id: params[:operator_id]).where(date: params[:presences].map{|p| DateTime.parse(p)}).delete_all
    params[:presences].map{|p| DateTime.parse(p)}.each do |p|
      OperatorPresence.create operator_id: params[:operator_id], date: p
    end

    render json: {}
  end

  def copy_day
    raise "no day given" unless params[:day]
    OperatorPresence.where("date >= ? AND date < ?", DateTime.parse(params[:day]), DateTime.parse(params[:day]) + 1.day).to_a.each do |opp|
      OperatorPresence.create date: opp.date + params[:days].to_i.days, operator_id: opp.operator_id
    end

    render json: {}
  end

  def reset_day
    raise "no day given" unless params[:day]
    OperatorPresence.where("date >= ? AND date < ?", DateTime.parse(params[:day]), DateTime.parse(params[:day]) + 1.day).delete_all

    render json: {}
  end

  def remove
    OperatorPresence.where(operator_id: params[:operator_id]).where(date: params[:presences].map{|p| DateTime.parse(p)}).delete_all

    render json: {}
  end
end