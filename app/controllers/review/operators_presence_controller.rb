class Review::OperatorsPresenceController < ReviewController

  skip_before_filter :verify_authenticity_token
  skip_before_filter :only_super_operator_level_2_or_admin
  before_filter :only_planning_access

  def index
    respond_to do |format|
      format.html {
        if params[:start]
          @operators = Operator.where(privilege: [Operator::PRIVILEGE_OPERATOR, Operator::PRIVILEGE_SUPER_OPERATOR_LEVEL_1, Operator::PRIVILEGE_SUPER_OPERATOR_LEVEL_2], active: true).includes(:operator_presences).sort_by(&:name).sort_by(&:level)
          render "index.csv"
          return
        end
      }
      format.json {
        render json: {
            status: "success",
            data: {
                operators: Operator.where(privilege: [Operator::PRIVILEGE_OPERATOR, Operator::PRIVILEGE_SUPER_OPERATOR_LEVEL_1, Operator::PRIVILEGE_SUPER_OPERATOR_LEVEL_2], active: true).includes(:operator_presences).sort_by(&:name).sort_by(&:level).map{|o|
                  presences = o.operator_presences.where("date >= ? AND date < ?", DateTime.parse(params[:start]), DateTime.parse(params[:start]) + 7.days)
                  {
                      name: o.name,
                      id: o.id,
                      stars: o.stars,
                      privilege: o.privilege,
                      in_formation: o.in_formation,
                      presences: presences.where(is_review: false).map{|op| op.date.strftime("%Y%m%dT%H%M00")},
                      review_presences: presences.where(is_review: true).map{|op| op.date.strftime("%Y%m%dT%H%M00")}
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

  private

  def only_planning_access
    if session[:planning_access]
      true
    else
      redirect_to "/"
      false
    end
  end
end