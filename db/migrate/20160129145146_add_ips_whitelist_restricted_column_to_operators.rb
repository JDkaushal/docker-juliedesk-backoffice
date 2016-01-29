class AddIpsWhitelistRestrictedColumnToOperators < ActiveRecord::Migration
  def change
    add_column :operators, :ips_whitelist_enabled, :boolean, default: true
  end
end
