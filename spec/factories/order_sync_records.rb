FactoryBot.define do
  factory :order_sync_record do
    earliest_ship_date do
      (Date.parse("#{Date.current.year}-01-01")..Date.parse("#{Date.current.year}-12-31")).to_a.sample
    end
  end
end
