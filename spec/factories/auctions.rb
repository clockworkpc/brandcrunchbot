FactoryBot.define do
  factory :auction do
    domain_name { 'MyString' }
    proxy_bid { 1 }
    bin_price { 1 }
  end
end
