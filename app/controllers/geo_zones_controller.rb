class GeoZonesController < ActionController::Base

  def autocomplete
    # - - - - - - - - - - - - - - - -
    # 2017-11-28 by Nico
    # Dirty static modification for Engie, as a POC. This has to integrated in a cleaner way in the future
    all_client_specific_zones = {
        'angelique.stoffels@engie.com': [
            'ZONE 1 _ LIEGE CENTRE',
            'ZONE 2 _ LIEGE PERIPHERIE',
            'ZONE 3 _ CANTONS DE L\'EST',
            'ZONE 4 - NAMUROIS'
        ]
    }
    client_specific_zones = (all_client_specific_zones["#{params[:account_email]}"] || []).select{|zone|
      zone.downcase.include? params[:query].downcase
    }.map{|zone|
      {
          label: zone,
          label_and_country: zone
      }
    }

    # - - - - - - - - - - - - - - - -

    geo_zones = GeoZone.
        where("lower(label) LIKE ?", "#{params[:query]}%".downcase).
        order(population: :desc).
        limit(5)

    render json: {
        status: 'success',
        data: geo_zones.as_json(methods: [:label_and_country]) + client_specific_zones
    }
  end
end