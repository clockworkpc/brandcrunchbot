class AddActiveToAuctions < ActiveRecord::Migration[7.1]
  def change
    add_column :auctions, :active, :boolean, default: true, null: false
  end
end
