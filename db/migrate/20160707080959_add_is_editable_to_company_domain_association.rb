class AddIsEditableToCompanyDomainAssociation < ActiveRecord::Migration
  def change
    add_column :company_domain_associations, :is_editable, :boolean, default: true
  end
end
