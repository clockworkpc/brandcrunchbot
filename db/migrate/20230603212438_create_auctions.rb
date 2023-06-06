class CreateAuctions < ActiveRecord::Migration[7.0]
  def change
    create_table :auctions do |t|
      t.string :domain
      t.integer :proxy_bid
      t.integer :bin_price

      t.timestamps
    end
  end
end
