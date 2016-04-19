class CreateCompanyDomainAssociations < ActiveRecord::Migration
  def change
    create_table :company_domain_associations do |t|
      t.string :company_name
      t.string :domain

      t.timestamps
    end

    add_index :company_domain_associations, [:company_name, :domain], unique: true
  end
end
