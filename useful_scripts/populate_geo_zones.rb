# http://download.geonames.org/export/dump/cities15000.txt
# http://download.geonames.org/export/dump/allCountries.txt

GeoZone.delete_all

cities_file_name = "/Users/nicolas/Downloads/cities15000.txt"
cities_data = File.read(cities_file_name)

cities_keys = [:geonameid,:name,:asciiname,:alternatenames,:latitude,:longitude,:feature_class,:feature_code,:country_code,:cc2,:admin1_code,:admin2_code,:admin3_code,:admin4_code,:population,:elevation,:dem,:timezone,:modification_date]

cities_lines = cities_data.split("\n").map {|line| Hash[line.split("\t").map.with_index{|item, i| [cities_keys[i], item]}]}

cities_geo_zone_attributes = cities_lines.map do |line|
  {
      label: line[:name],
      latitude: line[:latitude],
      longitude: line[:longitude],
      country_code: line[:country_code],
      population: line[:population],
      timezone: line[:timezone],
      kind: GeoZone::KIND_CITY
  }
end


GeoZone.create(cities_geo_zone_attributes)


countries_file_name = "/Users/nicolas/Downloads/countryInfo.txt"
countries_data = File.read(countries_file_name)

countries_keys = [:iso,:iso3,:iso_numeric, :fips, :country, :capital, :aera, :population, :continent, :tld, :currency_code, :currency_name, :phone, :postal_code_format, :postal_code_regex, :languages, :geoname_id, :neighbours, :equivalent_fips_code]


countries_lines = countries_data.split("\n").select{|line| !line.starts_with? "#"}.map {|line| Hash[line.split("\t").map.with_index{|item, i| [countries_keys[i], item]}]}

countries_geo_zone_attributes = countries_lines.map do |line|
  {
      label: line[:country],
      country_code: line[:iso],
      country: line[:country],
      population: line[:population],
      kind: GeoZone::KIND_COUNTRY
  }
end

GeoZone.create(countries_geo_zone_attributes)

GeoZone.where(kind: GeoZone::KIND_COUNTRY).each do |country|
  GeoZone.where(country_code: country.country_code).update_all(country: country.label)
end