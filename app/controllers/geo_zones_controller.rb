class GeoZonesController < ActionController::Base

  def autocomplete
    geo_zones = GeoZone.
        where("lower(label) LIKE ?", "#{params[:query]}%".downcase).
        order(population: :desc).
        limit(5)

    render json: {
        status: 'success',
        data: geo_zones.as_json(methods: [:label_and_country])
    }
  end
end