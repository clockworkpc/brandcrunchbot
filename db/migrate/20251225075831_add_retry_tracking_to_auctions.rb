class AddRetryTrackingToAuctions < ActiveRecord::Migration[7.1]
  def change
    add_column :auctions, :first_checked_at, :datetime
    add_column :auctions, :last_checked_at, :datetime
  end
end
