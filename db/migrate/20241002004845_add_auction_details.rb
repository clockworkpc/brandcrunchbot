class AddAuctionDetails < ActiveRecord::Migration[7.1]
  def change
    change_table :auctions, bulk: true do |t|
      t.boolean :is_valid, default: true, null: false
      t.datetime :auction_end_time
      t.integer :price
    end
  end
end
