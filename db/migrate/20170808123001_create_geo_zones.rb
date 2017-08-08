class CreateGeoZones < ActiveRecord::Migration
  def change
    create_table :geo_zones do |t|
      t.column :label, :string
      t.column :country_code, :string
      t.column :country, :string
      t.column :population, :integer
      t.column :latitude, :float
      t.column :longitude, :float
      t.column :kind, :string
      t.column :timezone, :string
      t.timestamps
    end
  end
end

