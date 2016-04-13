class Admin::FeaturesController < AdminController

  def index
    @features = Feature.all
  end

  def new
    @feature = Feature.new name: "New feature ##{Feature.count}"
  end

  def create
    @feature = Feature.create feature_params

    redirect_to action: :index
  end

  def edit
    @feature = Feature.find params[:id]
  end

  def update
    @feature = Feature.find params[:id]
    @feature.update feature_params

    redirect_to action: :index
  end

  def destroy
    Feature.delete params[:id]
    redirect_to action: :index
  end

  private

  def feature_params
    params.require(:feature).permit(:name, :description, :active_mode, :active_data)
  end
end