class AddPurchaseStatusToAuctions < ActiveRecord::Migration[7.1]
  def change
    add_column :auctions, :purchase_status, :string, default: 'pending'
  end
end
