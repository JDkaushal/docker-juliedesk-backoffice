class PerformanceController < ActionController::Base

  layout false
  MO1_FILE_NAME = "random_data_1mo.txt"

  def show
    @one_mo_data = File.read(MO1_FILE_NAME)
  end

  def download_1mo
    render file: MO1_FILE_NAME
  end

  def upload
    render json: {}
  end

  def blank
    render json: {}
  end
end