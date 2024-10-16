class RenameDomainToDomainNameInAuctions < ActiveRecord::Migration[7.1]
  def change
    rename_column :auctions, :domain, :domain_name
  end
end
