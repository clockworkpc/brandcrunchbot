FactoryBot.define do
  factory :finish_detail do
    finish_type { Faker::Science.element }
    finish_color { Faker::Color.color_name }
    finish_sheen { Faker::Science.modifier }
  end
end
