FactoryBot.define do
  factory :product_order do
    order { nil }
    product { nil }
    finish_detail { nil }
    line_subtotal { (100..1000).to_a.sample }
    finish_price { (10..99).to_a.sample }
    qty { (1..10).to_a.sample }
  end
end
