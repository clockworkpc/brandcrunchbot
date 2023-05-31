FactoryBot.define do
  factory :product_order_item do
    product_order { nil }
    line_number { 1 }
    unit_price { "9.99" }
    finish_price { "9.99" }
    quantity { 1 }
    specialty_price { "9.99" }
    line_total { "9.99" }
  end
end
