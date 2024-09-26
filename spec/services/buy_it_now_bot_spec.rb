require 'rails_helper'

RSpec.describe BuyItNowBot do
  it 'attempts to purchase a given domain', :focus do
    domain_name = 'teramode.com'
    target_price = 11
    service = described_class.new
    res = service.call(domain_name:, target_price:)
  end
end
