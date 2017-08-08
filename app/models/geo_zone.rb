class GeoZone < ActiveRecord::Base
  KIND_CITY = 'city'
  KIND_COUNTRY = 'country'

  def label_and_country
    "#{label} (#{country})"
  end
end