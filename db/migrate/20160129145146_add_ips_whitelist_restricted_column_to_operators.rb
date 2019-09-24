class AddIpsWhitelistRestrictedColumnToOperators < ActiveRecord::Migration[4.2]
  def change
    add_column :operators, :ips_whitelist_enabled, :boolean, default: true
  end
end
