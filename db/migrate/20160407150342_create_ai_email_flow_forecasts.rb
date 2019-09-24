class CreateAiEmailFlowForecasts < ActiveRecord::Migration[4.2]
  def change
    create_table :ai_email_flow_forecasts do |t|
      t.datetime :datetime, unique: true
      t.integer :count

      t.timestamps
    end
  end
end
