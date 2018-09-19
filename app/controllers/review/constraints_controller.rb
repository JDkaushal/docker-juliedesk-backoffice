class Review::ConstraintsController < ReviewController


  def main
    respond_to do |format|
      format.html do

      end

      format.json do
        render json: {
          status: 'success',
          data: {

          },
          mode: 'admin'
        }
      end
    end
  end

  def review
    respond_to do |format|
      format.html do
        render :main
      end

      format.json do
        render json: {
            status: 'success',
            data: {

            },
            mode: 'review'
        }
      end
    end

  end
end