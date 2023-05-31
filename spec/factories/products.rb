FactoryBot.define do
  factory :product do
    product_id { Faker::Number.number(digits: 3) }
    product_name { Faker::Beer.brand }
  end
end
