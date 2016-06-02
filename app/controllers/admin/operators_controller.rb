class Admin::OperatorsController < AdminController

  def index
    @operators = Operator.all
  end

  def new
    @operator = Operator.new(email: "@operator.juliedesk.com", active: true)
  end

  def edit
    @operator = Operator.find(params[:id])
  end

  def update
    @operator = Operator.find(params[:id])
    # Seems like http params nil is passed as an empty string
    op_params = operators_params
    op_params[:privilege] = op_params[:privilege] == '' ? nil : op_params[:privilege]
    @operator.update_attributes op_params
    redirect_to action: :index
  end

  def create
    operator = Operator.new(operators_params)
    operator.save

    redirect_to action: :index
  end

  def disable
    operator = Operator.find params[:id]
    operator.update_attributes({
                                   active: false,
                                   enabled: false
                               })
    redirect_to action: :index
  end

  private

  def operators_params
    params.require(:operator).permit(:email, :name, :ips_whitelist_enabled, :active, :password, :privilege, :color, :planning_access, :in_formation, :manager_access)
  end
end