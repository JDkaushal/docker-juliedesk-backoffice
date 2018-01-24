class GeoZonesController < ActionController::Base

  def autocomplete
    # - - - - - - - - - - - - - - - -
    # 2017-11-28 by Nico
    # Dirty static modification for Engie, as a POC. This has to integrated in a cleaner way in the future
    all_client_specific_zones = {
      'angelique.stoffels@engie.com' => [
        'REGION DE NAMUR',
        'CANTONS DE L\'EST',
        'PERIPHERIE DE LIEGE'
      ],
      'julie.lebrun@engie.com' => [
        'Zone Luxembourg',
        'Zone Hainaut',
        'Zone Namur+Hainaut',
        'Zone Namur'
      ],
      'yacine@juliedesk.com' => [
        'REGION DE NAMUR',
        'CANTONS DE L\'EST',
        'PERIPHERIE DE LIEGE'
      ],
      'veronique.godfrin@engie.com' => [
        'région Mons',
        'région Tournai',
        'région Charleroi',
        'région Luxembourg'
      ],
      'dominique.cappelle@engie.com' => [
        'Zone 1',
        'Zone 2',
        'Zone 3',
        'Zone 4',
        'Zone 5'
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