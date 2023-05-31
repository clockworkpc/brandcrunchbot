FactoryBot.define do
  my_ship_date = (Date.parse(Utils.first_day_two_months_ago)..Date.parse(Utils.last_day_two_months_hence)).to_a.sample
  factory :order do
    customer { nil }
    order_number { Faker::Number.number(digits: 5) }
    ship_date { my_ship_date }
    completed_at { Date.parse(ship_date) - 3 }
    order_name { Faker::Fantasy::Tolkien.location }
    status_history { nil }
  end
end
