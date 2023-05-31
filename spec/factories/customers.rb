FactoryBot.define do
  factory :customer do
    allmoxy_id { Faker::Number.number(digits: 5) }
    customer_name { Faker::Company.name }
  end
end
